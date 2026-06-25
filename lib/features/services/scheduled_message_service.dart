import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Free-tier scheduled-message delivery.
///
/// Cloud Functions (true server-side cron) require the paid Blaze plan, so we
/// stay on the free Spark plan with a client-side delivery model:
///
///   * A scheduled message is written to `scheduledMessages` with a
///     `scheduledFor` timestamp and `delivered: false`.
///   * While the sender's app is running, [start] polls every 30s (and on
///     launch) for that user's due-but-undelivered messages and posts them into
///     the real chat, then marks them delivered.
///
/// Limitation: delivery happens when the sender's device next has the app open
/// at/after the scheduled time. This is the realistic free-plan tradeoff.
class ScheduledMessageService {
  ScheduledMessageService(this.currentUserEmail);

  final String currentUserEmail;
  Timer? _timer;

  static final _db = FirebaseFirestore.instance;

  /// Schedule a message for future delivery into [chatId].
  static Future<void> schedule({
    required String chatId,
    required String collection, // 'chats' or 'groupChats'
    required String sender,
    required String text,
    required DateTime scheduledFor,
    List<String> imageUrls = const [],
    String? audioUrl,
    String? toLabel, // who it's going to, for display
  }) async {
    await _db.collection('scheduledMessages').add({
      'chatId': chatId,
      'collection': collection,
      'sender': sender,
      'text': text,
      'imageUrls': imageUrls,
      'audioUrl': audioUrl,
      'toLabel': toLabel ?? chatId,
      'scheduledFor': Timestamp.fromDate(scheduledFor),
      'delivered': false,
      'status': 'pending', // pending | delivered | failed
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Stream of ALL this user's scheduled messages (pending, delivered, failed)
  /// for the "Scheduled" management screen.
  ///
  /// Uses only a single equality filter (auto-indexed) and sorts client-side,
  /// so it needs no Firestore composite index.
  Stream<QuerySnapshot<Map<String, dynamic>>> allStream() {
    return _db
        .collection('scheduledMessages')
        .where('sender', isEqualTo: currentUserEmail)
        .snapshots();
  }

  static Future<void> cancel(String scheduledId) =>
      _db.collection('scheduledMessages').doc(scheduledId).delete();

  /// Begin polling for due messages.
  void start() {
    _deliverDue();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _deliverDue());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _deliverDue() async {
    try {
      final now = DateTime.now();
      // Single-field query (no composite index); filter due+pending in Dart.
      final snap = await _db
          .collection('scheduledMessages')
          .where('sender', isEqualTo: currentUserEmail)
          .get();

      final due = snap.docs.where((d) {
        final data = d.data();
        if ((data['status'] as String?) != 'pending') return false;
        final when = (data['scheduledFor'] as Timestamp?)?.toDate();
        return when != null && !when.isAfter(now);
      });

      for (final doc in due) {
        final data = doc.data();
        try {
          final chatId = data['chatId'] as String;
          final collection = data['collection'] as String? ?? 'chats';

          final messageData = <String, dynamic>{
            'text': data['text'] ?? '',
            'sender': data['sender'],
            'timestamp': FieldValue.serverTimestamp(),
            'imageUrls': data['imageUrls'] ?? [],
          };
          if (data['audioUrl'] != null) {
            messageData['audioUrl'] = data['audioUrl'];
          }

          await _db
              .collection(collection)
              .doc(chatId)
              .collection('messages')
              .add(messageData);

          final preview = (data['text'] as String?)?.isNotEmpty == true
              ? data['text']
              : (data['audioUrl'] != null ? '🎤 Voice message' : '📷 Photo');
          await _db.collection(collection).doc(chatId).update({
            'lastMessage': preview,
            'timestamp': FieldValue.serverTimestamp(),
          });

          await doc.reference
              .update({'delivered': true, 'status': 'delivered'});
        } catch (e) {
          // Permanent failure for this item (e.g. chat deleted). Mark it so the
          // user sees it in the Scheduled screen instead of retrying forever.
          await doc.reference.update({'status': 'failed'});
        }
      }
    } catch (_) {
      // Outer query failed (offline); leave items pending and retry next tick.
    }
  }
}
