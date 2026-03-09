import 'package:chat_app/features/chat/screens/group_chat/group_details/group_details_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class GroupChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String groupName;
  final String? groupPhotoUrl;
  final String chatId;

  const GroupChatAppBar({
    super.key,
    required this.groupName,
    required this.groupPhotoUrl,
    required this.chatId,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 10);

  Stream<DocumentSnapshot> _groupStream() {
    return FirebaseFirestore.instance
        .collection('groupChats')
        .doc(chatId)
        .snapshots();
  }

  void _openDetails(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GroupDetailsPage(
          groupName: groupName,
          groupPhotoUrl: groupPhotoUrl,
          chatId: chatId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      toolbarHeight: kToolbarHeight + 10,
      leadingWidth: 40,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded,
            color: Colors.white, size: 20),
        onPressed: () => Navigator.of(context).pop(),
      ),
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [const Color(0xFF1565C0), Colors.blue.shade700],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.shade900.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
      ),
      title: StreamBuilder<DocumentSnapshot>(
        stream: _groupStream(),
        builder: (context, snapshot) {
          final data = snapshot.data?.data() as Map<String, dynamic>?;
          final participants = data?['participants'] as List<dynamic>? ?? [];
          final memberCount = participants.length;
          final photoUrl = data?['groupPhotoUrl'] as String? ?? groupPhotoUrl;

          return GestureDetector(
            onTap: () => _openDetails(context),
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                // Group avatar
                Hero(
                  tag: 'group-avatar-$chatId',
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withOpacity(0.4), width: 2),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(21),
                      child: photoUrl != null && photoUrl.isNotEmpty
                          ? Image.network(
                              photoUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _defaultAvatar(),
                            )
                          : _defaultAvatar(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Name + member count
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        groupName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15.5,
                          letterSpacing: 0.1,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        memberCount > 0
                            ? '$memberCount member${memberCount == 1 ? '' : 's'}'
                            : 'Group',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.75),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.videocam_rounded,
              color: Colors.white, size: 24),
          onPressed: () {},
          tooltip: 'Video Call',
        ),
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.info_outline_rounded,
                color: Colors.white, size: 18),
          ),
          onPressed: () => _openDetails(context),
          tooltip: 'Group Info',
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _defaultAvatar() {
    return Container(
      color: Colors.blue.shade400,
      child: const Icon(Icons.group_rounded, color: Colors.white, size: 22),
    );
  }
}