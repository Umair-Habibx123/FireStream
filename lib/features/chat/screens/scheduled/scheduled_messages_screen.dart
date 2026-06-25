import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:chat_app/features/services/scheduled_message_service.dart';

/// Lists every message the user has scheduled, with its delivery status
/// (Pending / Delivered / Failed) and the ability to cancel a pending one.
class ScheduledMessagesScreen extends StatelessWidget {
  final String currentUserEmail;

  const ScheduledMessagesScreen({super.key, required this.currentUserEmail});

  @override
  Widget build(BuildContext context) {
    final service = ScheduledMessageService(currentUserEmail);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scheduled Messages',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: service.allStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _centered(
              context,
              Icons.error_outline_rounded,
              'Could not load',
              'If this persists, the Firestore index may still be building.',
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs.toList()
            ..sort((a, b) {
              final ta = (a.data()['scheduledFor'] as Timestamp?)?.toDate();
              final tb = (b.data()['scheduledFor'] as Timestamp?)?.toDate();
              if (ta == null || tb == null) return 0;
              return tb.compareTo(ta); // newest first
            });
          if (docs.isEmpty) {
            return _centered(
              context,
              Icons.schedule_send_rounded,
              'No scheduled messages',
              'Use the clock icon in a chat to schedule a message for later.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) => _tile(context, docs[i]),
          );
        },
      ),
    );
  }

  Widget _tile(
      BuildContext context, QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final status = (data['status'] as String?) ?? 'pending';
    final scheduledFor = (data['scheduledFor'] as Timestamp?)?.toDate();
    final text = (data['text'] as String?)?.trim();
    final hasImages = (data['imageUrls'] as List?)?.isNotEmpty ?? false;
    final hasAudio = (data['audioUrl'] as String?)?.isNotEmpty ?? false;

    final preview = (text != null && text.isNotEmpty)
        ? text
        : hasAudio
            ? '🎤 Voice message'
            : hasImages
                ? '📷 Photo'
                : '(empty)';

    final (Color color, IconData icon, String label) = switch (status) {
      'delivered' => (Colors.green, Icons.check_circle_rounded, 'Delivered'),
      'failed' => (Colors.red, Icons.error_rounded, 'Failed'),
      _ => (Colors.orange, Icons.schedule_rounded, 'Pending'),
    };

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('To: ${data['toLabel'] ?? data['chatId'] ?? ''}',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(preview,
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(label,
                          style: TextStyle(
                              color: color,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                      const Text('  •  ',
                          style: TextStyle(color: Colors.grey)),
                      Flexible(
                        child: Text(
                          scheduledFor == null
                              ? ''
                              : DateFormat('MMM d, h:mm a')
                                  .format(scheduledFor),
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (status == 'pending')
              IconButton(
                tooltip: 'Cancel',
                icon: const Icon(Icons.delete_outline_rounded,
                    color: Colors.red),
                onPressed: () => ScheduledMessageService.cancel(doc.id),
              )
            else
              IconButton(
                tooltip: 'Remove',
                icon: Icon(Icons.close_rounded,
                    color: Colors.grey.shade400, size: 20),
                onPressed: () => ScheduledMessageService.cancel(doc.id),
              ),
          ],
        ),
      ),
    );
  }

  Widget _centered(
      BuildContext context, IconData icon, String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(title,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }
}
