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
  StreamSubscription? _messageSubscription;
  late Stream<Map<String, dynamic>> _latestMessageStream;

  @override
  void initState() {
    super.initState();
    _latestMessageStream = _getLatestGroupMessageStream();
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    super.dispose();
  }

  Stream<Map<String, dynamic>> _getLatestGroupMessageStream() {
    final messagesRef = FirebaseFirestore.instance
        .collection('groupChats')
        .doc(widget.chat.id)
        .collection('messages');

    return messagesRef
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isNotEmpty) {
            final latestMessageDoc = snapshot.docs.first;
            bool hasImages =
                latestMessageDoc['imageUrls'] != null &&
                (latestMessageDoc['imageUrls'] as List).isNotEmpty;

            return {
              'text':
                  hasImages
                      ? '<image>'
                      : (latestMessageDoc['text'] ?? 'No messages yet'),
              'timestamp': latestMessageDoc['timestamp'] as Timestamp?,
            };
          }
          return {'text': 'No messages yet', 'timestamp': null};
        });
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) {
      return '';
    }
    DateTime dateTime = timestamp.toDate();
    return "${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    var admins = widget.chat['admins'] as List<dynamic>;
    bool settingOnlyAdmin = widget.chat['SettingOnlyAdmin'] ?? false;
    String groupName = widget.chat['groupName'] ?? 'Group Chat';
    String? groupPhotoUrl = widget.chat['groupPhotoUrl'];
    bool isAdmin = admins.contains(widget.currentUserEmail);

    return StreamBuilder<Map<String, dynamic>>(
      stream: _latestMessageStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingCard();
        }

        if (snapshot.hasError) {
          return _buildErrorCard();
        }

        final messageData =
            snapshot.data ?? {'text': 'No messages yet', 'timestamp': null};
        final String messageText = messageData['text'] ?? 'No messages yet';
        final Timestamp? timestamp = messageData['timestamp'];

        return _buildGroupChatCard(
          context,
          groupName: groupName,
          groupPhotoUrl: groupPhotoUrl,
          isAdmin: isAdmin,
          settingOnlyAdmin: settingOnlyAdmin,
          messageText: messageText,
          timestamp: timestamp,
        );
      },
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      height: 80,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade100.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Center(
        child: CircularProgressIndicator.adaptive(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      height: 80,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: const Center(
        child: ListTile(
          leading: Icon(Icons.error_outline, color: Colors.red),
          title: Text(
            'Error loading group chat',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      ),
    );
  }

  Widget _buildGroupChatCard(
    BuildContext context, {
    required String groupName,
    required String? groupPhotoUrl,
    required bool isAdmin,
    required bool settingOnlyAdmin,
    required String messageText,
    required Timestamp? timestamp,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade100.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => GroupChatScreen(
                      chatId: widget.chat.id,
                      currentUserEmail: widget.currentUserEmail,
                      groupName: groupName,
                      groupPhotoUrl: groupPhotoUrl,
                    ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.blue.shade100, width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child:
                        groupPhotoUrl != null && groupPhotoUrl.isNotEmpty
                            ? Image.network(
                              groupPhotoUrl,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (context, error, stackTrace) =>
                                      const Icon(Icons.group, size: 28),
                            )
                            : const Icon(Icons.group, size: 28),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              groupName,
                              style: Theme.of(
                                context,
                              ).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade800,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isAdmin)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Admin',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        messageText,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatTimestamp(timestamp),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!settingOnlyAdmin || isAdmin)
                          IconButton(
                            icon: Icon(
                              Icons.settings_outlined,
                              color: Colors.blue.shade400,
                              size: 20,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => ChatSettingsScreen(
                                        chatId: widget.chat.id,
                                      ),
                                ),
                              );
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        IconButton(
                          icon: Icon(
                            Icons.chevron_right,
                            color: Colors.blue.shade400,
                            size: 20,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => GroupChatScreen(
                                      chatId: widget.chat.id,
                                      currentUserEmail: widget.currentUserEmail,
                                      groupName: groupName,
                                      groupPhotoUrl: groupPhotoUrl,
                                    ),
                              ),
                            );
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
