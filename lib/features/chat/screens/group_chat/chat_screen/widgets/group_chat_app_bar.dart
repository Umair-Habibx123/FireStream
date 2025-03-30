import 'package:chat_app/features/chat/screens/group_chat/group_details/group_details_page.dart';
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
  Widget build(BuildContext context) {
    return AppBar(
      title: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GroupDetailsPage(
                groupName: groupName,
                groupPhotoUrl: groupPhotoUrl,
                chatId: chatId,
              ),
            ),
          );
        },
        child: Row(
          children: [
            Hero(
              tag: 'group-avatar-$chatId',
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: groupPhotoUrl != null && groupPhotoUrl!.isNotEmpty
                      ? Image.network(
                          groupPhotoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.group,
                            size: 20,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        )
                      : Icon(
                          Icons.group,
                          size: 20,
                          color: Colors.white.withOpacity(0.8),
                        ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    groupName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16.0,
                      letterSpacing: 0.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Online • 5 members', // Make dynamic
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12.0,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.blueAccent,
      iconTheme: const IconThemeData(color: Colors.white),
      elevation: 1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(12),
        ),
      ),
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blueAccent,
              Colors.blue.shade700,
            ],
          ),
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(12),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.2),
            ),
            child: const Icon(
              Icons.info_outline,
              size: 22,
              color: Colors.white,
            ),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GroupDetailsPage(
                  groupName: groupName,
                  groupPhotoUrl: groupPhotoUrl,
                  chatId: chatId,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 10);
}