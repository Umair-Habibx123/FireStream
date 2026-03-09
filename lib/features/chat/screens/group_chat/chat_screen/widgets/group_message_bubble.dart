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

  bool get _isMine => senderEmail == currentUserEmail;
  bool get _hasImages => imageUrls != null && imageUrls!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => onLongPress(messageText),
      child: Padding(
        padding: EdgeInsets.only(
          top: 3,
          bottom: 3,
          left: _isMine ? 48 : 8,
          right: _isMine ? 8 : 48,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment:
              _isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            // Other user's avatar
            if (!_isMine) _buildAvatar(),

            const SizedBox(width: 8),

            Flexible(
              child: Column(
                crossAxisAlignment: _isMine
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  // Sender name (only for others)
                  if (!_isMine) _buildSenderName(),

                  // Images
                  if (_hasImages)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: GroupImageBubble(
                        imageUrls: imageUrls!,
                        isSentByCurrentUser: _isMine,
                        onImageTap: onImageTap,
                      ),
                    ),

                  // Text bubble
                  if (messageText.isNotEmpty) _buildTextBubble(),

                  // Timestamp
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      _formatTimestamp(timestamp),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade400,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(senderEmail)
          .get(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final profilePicUrl = data?['profilePic'] as String? ?? '';

        return GestureDetector(
          onTap: () => onUserTap(senderEmail),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.blue.shade100, width: 1.5),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: profilePicUrl.isNotEmpty
                  ? Image.network(
                      profilePicUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _defaultAvatarContent(),
                    )
                  : _defaultAvatarContent(),
            ),
          ),
        );
      },
    );
  }

  Widget _defaultAvatarContent() {
    return Container(
      color: Colors.blue.shade50,
      child: Icon(Icons.person_rounded,
          size: 16, color: Colors.blue.shade300),
    );
  }

  Widget _buildSenderName() {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(senderEmail)
          .get(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final username = data?['username'] as String? ??
            senderEmail.split('@')[0];

        return Padding(
          padding: const EdgeInsets.only(bottom: 4, left: 2),
          child: Text(
            username,
            style: TextStyle(
              color: _nameColor(senderEmail),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextBubble() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _isMine ? const Color(0xFF1565C0) : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(_isMine ? 18 : 4),
          bottomRight: Radius.circular(_isMine ? 4 : 18),
        ),
        boxShadow: [
          BoxShadow(
            color: _isMine
                ? const Color(0xFF1565C0).withOpacity(0.22)
                : Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        messageText,
        style: TextStyle(
          color: _isMine ? Colors.white : const Color(0xFF1A1A2E),
          fontSize: 15,
          height: 1.45,
          letterSpacing: 0.1,
        ),
      ),
    );
  }

  /// Generates a deterministic color per sender email for name labels
  Color _nameColor(String email) {
    const colors = [
      Color(0xFF0D47A1),
      Color(0xFF1B5E20),
      Color(0xFF4A148C),
      Color(0xFF880E4F),
      Color(0xFFE65100),
      Color(0xFF006064),
      Color(0xFF37474F),
    ];
    int index = email.codeUnits.fold(0, (a, b) => a + b) % colors.length;
    return colors[index];
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final dt = timestamp.toDate();
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    }
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}