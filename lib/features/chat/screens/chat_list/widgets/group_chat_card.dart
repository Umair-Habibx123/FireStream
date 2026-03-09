import 'dart:async';

import 'package:chat_app/features/chat/screens/group_chat/chat_screen/group_chat_screen.dart';
import 'package:chat_app/features/chat/screens/group_chat/group_setting/chat_settings_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class GroupChatCard extends StatefulWidget {
  final QueryDocumentSnapshot chat;
  final String currentUserEmail;

  const GroupChatCard({
    super.key,
    required this.chat,
    required this.currentUserEmail,
  });

  @override
  _GroupChatCardState createState() => _GroupChatCardState();
}

class _GroupChatCardState extends State<GroupChatCard> {
  late Stream<Map<String, dynamic>> _latestMessageStream;

  @override
  void initState() {
    super.initState();
    _latestMessageStream = _getLatestGroupMessageStream();
  }

  Stream<Map<String, dynamic>> _getLatestGroupMessageStream() {
    return FirebaseFirestore.instance
        .collection('groupChats')
        .doc(widget.chat.id)
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
    final admins = widget.chat['admins'] as List<dynamic>;
    final bool settingOnlyAdmin = widget.chat['SettingOnlyAdmin'] ?? false;
    final String groupName = widget.chat['groupName'] ?? 'Group Chat';
    final String? groupPhotoUrl = widget.chat['groupPhotoUrl'];
    final bool isAdmin = admins.contains(widget.currentUserEmail);

    return StreamBuilder<Map<String, dynamic>>(
      stream: _latestMessageStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildSkeleton();
        }

        final msgData =
            snapshot.data ?? {'text': 'No messages yet', 'timestamp': null, 'sender': ''};
        final String messageText = msgData['text'] ?? 'No messages yet';
        final Timestamp? timestamp = msgData['timestamp'];
        final bool isMyMessage =
            msgData['sender'] == widget.currentUserEmail;

        return _buildCard(
          context,
          groupName: groupName,
          groupPhotoUrl: groupPhotoUrl,
          isAdmin: isAdmin,
          settingOnlyAdmin: settingOnlyAdmin,
          messageText: messageText,
          timestamp: timestamp,
          isMyMessage: isMyMessage,
        );
      },
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required String groupName,
    required String? groupPhotoUrl,
    required bool isAdmin,
    required bool settingOnlyAdmin,
    required String messageText,
    required Timestamp? timestamp,
    required bool isMyMessage,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GroupChatScreen(
              chatId: widget.chat.id,
              currentUserEmail: widget.currentUserEmail,
              groupName: groupName,
              groupPhotoUrl: groupPhotoUrl,
            ),
          ),
        ),
        splashColor: const Color(0xFF1565C0).withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Group avatar
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isAdmin
                            ? Colors.blue.shade200
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(27),
                      child: groupPhotoUrl != null && groupPhotoUrl.isNotEmpty
                          ? Image.network(
                              groupPhotoUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _defaultGroupAvatar(),
                            )
                          : _defaultGroupAvatar(),
                    ),
                  ),
                  if (isAdmin)
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1565C0),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: const Icon(Icons.star_rounded,
                            size: 9, color: Colors.white),
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
                            groupName,
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
                                size: 14, color: Colors.blue.shade300),
                          ),
                        Expanded(
                          child: Text(
                            messageText,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Settings icon (if allowed)
                        if (!settingOnlyAdmin || isAdmin)
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatSettingsScreen(
                                    chatId: widget.chat.id),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Icon(Icons.settings_rounded,
                                  size: 16, color: Colors.grey.shade400),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _defaultGroupAvatar() {
    return Container(
      color: Colors.blue.shade50,
      child: Icon(Icons.group_rounded,
          size: 26, color: Colors.blue.shade300),
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
                _shimmer(130, 14, radius: 4),
                const SizedBox(height: 8),
                _shimmer(190, 12, radius: 4),
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