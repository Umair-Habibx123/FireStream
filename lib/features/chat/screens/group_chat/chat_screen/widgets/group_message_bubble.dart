import 'package:chat_app/features/chat/screens/group_chat/chat_screen/widgets/group_image_bubble.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GroupMessageBubble extends StatelessWidget {
  final String messageText;
  final String senderEmail;
  final String currentUserEmail;
  final List<dynamic>? imageUrls;
  final Timestamp? timestamp;
  final Function(String) onLongPress;
  final Function(String) onUserTap;
  final Function(String)? onImageTap;

  const GroupMessageBubble({
    super.key,
    required this.messageText,
    required this.senderEmail,
    required this.currentUserEmail,
    required this.imageUrls,
    required this.timestamp,
    required this.onLongPress,
    required this.onUserTap,
    required this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSentByCurrentUser = senderEmail == currentUserEmail;
    final bool showAvatar = !isSentByCurrentUser;
    bool hasImages = imageUrls != null && imageUrls!.isNotEmpty;

    return GestureDetector(
      onLongPress: () => onLongPress(messageText),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Align(
          alignment:
              isSentByCurrentUser
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.8,
            ),
            child: Padding(
              padding: EdgeInsets.only(
                left: isSentByCurrentUser ? 40 : 8,
                right: isSentByCurrentUser ? 8 : 40,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showAvatar)
                    FutureBuilder<DocumentSnapshot>(
                      future:
                          FirebaseFirestore.instance
                              .collection('users')
                              .doc(senderEmail)
                              .get(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Container(
                            width: 32,
                            height: 32,
                            margin: const EdgeInsets.only(right: 8),
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          );
                        }
                        if (snapshot.hasError || !snapshot.hasData) {
                          return Container(
                            width: 32,
                            height: 32,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey.shade300,
                            ),
                            child: Icon(
                              Icons.person,
                              size: 16,
                              color: Colors.grey.shade600,
                            ),
                          );
                        }
                        var userData = snapshot.data!;
                        String profilePicUrl = userData['profilePic'] ?? '';

                        return GestureDetector(
                          onTap: () => onUserTap(senderEmail),
                          child: Container(
                            width: 32,
                            height: 32,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.blue.shade100,
                                width: 1.5,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child:
                                  profilePicUrl.isNotEmpty
                                      ? Image.network(
                                        profilePicUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (_, __, ___) => Icon(
                                              Icons.person,
                                              size: 16,
                                              color: Colors.grey.shade600,
                                            ),
                                      )
                                      : Icon(
                                        Icons.person,
                                        size: 16,
                                        color: Colors.grey.shade600,
                                      ),
                            ),
                          ),
                        );
                      },
                    ),
                  Flexible(
                    child: Column(
                      crossAxisAlignment:
                          isSentByCurrentUser
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                      children: [
                        if (!isSentByCurrentUser)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              senderEmail.split('@')[0],
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        if (hasImages)
                          GroupImageBubble(
                            imageUrls: imageUrls!,
                            isSentByCurrentUser: isSentByCurrentUser,
                            onImageTap: onImageTap,
                          ),
                        if (messageText.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isSentByCurrentUser
                                      ? Colors.blueAccent
                                      : Colors.grey.shade200,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16),
                                topRight: const Radius.circular(16),
                                bottomLeft:
                                    isSentByCurrentUser
                                        ? const Radius.circular(16)
                                        : const Radius.circular(4),
                                bottomRight:
                                    isSentByCurrentUser
                                        ? const Radius.circular(4)
                                        : const Radius.circular(16),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              messageText,
                              style: TextStyle(
                                color:
                                    isSentByCurrentUser
                                        ? Colors.white
                                        : Colors.grey.shade800,
                                fontSize: 15,
                                height: 1.4,
                              ),
                            ),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          _formatTimestamp(timestamp),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Now';

    DateTime dateTime = timestamp.toDate();
    DateTime now = DateTime.now();

    if (dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day) {
      return "${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}";
    } else {
      return "${_formatDate(dateTime)}, ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}";
    }
  }

  String _formatDate(DateTime dateTime) {
    const monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return "${monthNames[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}";
  }
}
