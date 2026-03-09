import 'dart:async';
import 'package:chat_app/features/chat/screens/individual_chat/chat_screen/chat_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class ChatCard extends StatefulWidget {
  final String chatId;
  final String currentUserEmail;
  final String otherParticipant;

  const ChatCard({
    super.key,
    required this.chatId,
    required this.currentUserEmail,
    required this.otherParticipant,
  });

  @override
  _ChatCardState createState() => _ChatCardState();
}

class _ChatCardState extends State<ChatCard> {
  late Stream<Map<String, dynamic>> _latestMessageStream;
  late Stream<DocumentSnapshot> _userStatusStream;
  late Future<String?> _profilePictureFuture;
  late Future<bool> _isContactSavedFuture;

  @override
  void initState() {
    super.initState();
    _latestMessageStream = _getLatestMessageStream();
    _profilePictureFuture = _getProfilePicture();
    _isContactSavedFuture = _isContactSaved();
    _userStatusStream = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.otherParticipant)
        .snapshots();
  }

  Stream<Map<String, dynamic>> _getLatestMessageStream() {
    return FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        bool hasImages =
            doc['imageUrls'] != null && (doc['imageUrls'] as List).isNotEmpty;
        return {
          'text': hasImages ? '📷 Photo' : (doc['text'] ?? 'No messages yet'),
          'timestamp': doc['timestamp'] as Timestamp?,
          'sender': doc['sender'] as String? ?? '',
        };
      }
      return {'text': 'No messages yet', 'timestamp': null, 'sender': ''};
    });
  }

  Future<String?> _getProfilePicture() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.otherParticipant)
          .get();
      if (userDoc.exists) return userDoc['profilePic'] ?? '';
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> _isContactSaved() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUserEmail)
          .collection('contacts')
          .doc('savedContacts')
          .get();
      if (doc.exists) {
        List<dynamic> emails = doc['contactEmails'] ?? [];
        return emails.contains(widget.otherParticipant);
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> _deleteChat() async {
    try {
      final chatRef = FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId);

      await chatRef
          .update({'deletedBy': FieldValue.arrayUnion([widget.currentUserEmail])});

      final chatDoc = await chatRef.get();
      List<dynamic> deletedBy = chatDoc['deletedBy'] ?? [];

      if (deletedBy.length == 2) {
        final messagesSnapshot = await chatRef.collection('messages').get();
        for (var messageDoc in messagesSnapshot.docs) {
          var data = messageDoc.data();
          if (data['imageUrls'] != null && data['imageUrls'] is List) {
            for (var url in List<String>.from(data['imageUrls'])) {
              try {
                await FirebaseStorage.instance.refFromURL(url).delete();
              } catch (_) {}
            }
          }
          await messageDoc.reference.delete();
        }
        await chatRef.delete();
      }
    } catch (e) {
      debugPrint('Error deleting chat: $e');
    }
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Chat',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text(
            'Are you sure you want to delete this conversation?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child:
                Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _deleteChat();
            },
            child: const Text('Delete',
                style: TextStyle(
                    color: Color(0xFFE53935), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final dt = timestamp.toDate();
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    }
    final diff = now.difference(dt);
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[dt.weekday - 1];
    }
    return '${dt.day}/${dt.month}';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Future.wait([_profilePictureFuture, _isContactSavedFuture]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildSkeleton();
        }

        final String? profileUrl = snapshot.data?[0] as String?;
        final bool isSavedContact = snapshot.data?[1] as bool? ?? false;

        return StreamBuilder<DocumentSnapshot>(
          stream: _userStatusStream,
          builder: (context, statusSnap) {
            final userData =
                statusSnap.data?.data() as Map<String, dynamic>?;
            final isOnline = userData?['isOnline'] as bool? ?? false;
            final username = userData?['username'] as String? ??
                widget.otherParticipant;

            return StreamBuilder<Map<String, dynamic>>(
              stream: _latestMessageStream,
              builder: (context, messageSnap) {
                final msgData = messageSnap.data ??
                    {'text': 'No messages yet', 'timestamp': null, 'sender': ''};
                final String messageText = msgData['text'] ?? 'No messages yet';
                final Timestamp? timestamp = msgData['timestamp'];
                final bool isMyMessage =
                    msgData['sender'] == widget.currentUserEmail;

                return _buildCard(
                  profileUrl: profileUrl,
                  username: username,
                  isOnline: isOnline,
                  isSavedContact: isSavedContact,
                  messageText: messageText,
                  timestamp: timestamp,
                  isMyMessage: isMyMessage,
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildCard({
    required String? profileUrl,
    required String username,
    required bool isOnline,
    required bool isSavedContact,
    required String messageText,
    required Timestamp? timestamp,
    required bool isMyMessage,
  }) {
    return Dismissible(
      key: Key(widget.chatId),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        _showDeleteDialog();
        return false; // we handle deletion manually
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_rounded, color: Colors.red.shade400, size: 24),
            const SizedBox(height: 4),
            Text('Delete',
                style: TextStyle(
                    color: Colors.red.shade400,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen(
                chatId: widget.chatId,
                currentUserEmail: widget.currentUserEmail,
                otherParticipantEmail: widget.otherParticipant,
              ),
            ),
          ),
          splashColor: const Color(0xFF1565C0).withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Avatar with online dot
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSavedContact
                              ? Colors.amber.shade300
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(27),
                        child: profileUrl != null && profileUrl.isNotEmpty
                            ? Image.network(
                                profileUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _defaultAvatar(),
                              )
                            : _defaultAvatar(),
                      ),
                    ),
                    // Online indicator
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 13,
                        height: 13,
                        decoration: BoxDecoration(
                          color: isOnline
                              ? const Color(0xFF00E676)
                              : Colors.transparent,
                          shape: BoxShape.circle,
                          border: isOnline
                              ? Border.all(color: Colors.white, width: 2)
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),

                // Text info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              username,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: Color(0xFF1A1A2E),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            _formatTimestamp(timestamp),
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Colors.grey.shade400,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (isMyMessage && messageText != 'No messages yet')
                            Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Icon(Icons.done_all_rounded,
                                  size: 14,
                                  color: Colors.blue.shade300),
                            ),
                          Expanded(
                            child: Text(
                              messageText,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w400,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isSavedContact)
                            Icon(Icons.star_rounded,
                                size: 14, color: Colors.amber.shade400),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _defaultAvatar() {
    return Container(
      color: Colors.blue.shade50,
      child: Icon(Icons.person_rounded,
          size: 28, color: Colors.blue.shade300),
    );
  }

  Widget _buildSkeleton() {
    return Container(
      height: 78,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          _shimmer(54, 54, radius: 27),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _shimmer(120, 14, radius: 4),
                const SizedBox(height: 8),
                _shimmer(180, 12, radius: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _shimmer(double w, double h, {double radius = 4}) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}