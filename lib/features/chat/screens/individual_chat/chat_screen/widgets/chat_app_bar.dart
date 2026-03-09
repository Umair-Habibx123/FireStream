import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Future<String?> profileUrlFuture;
  final String otherParticipantEmail;
  final VoidCallback onTap;

  const ChatAppBar({
    super.key,
    required this.profileUrlFuture,
    required this.otherParticipantEmail,
    required this.onTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 10);

  /// Fetches real-time online/last seen from Firestore user doc.
  /// Expects fields: `isOnline` (bool) and `lastSeen` (Timestamp) on the user document.
  Stream<DocumentSnapshot> _userStatusStream() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(otherParticipantEmail)
        .snapshots();
  }

  String _formatLastSeen(Timestamp? ts) {
    if (ts == null) return 'Last seen recently';
    final dt = ts.toDate();
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'Last seen just now';
    if (diff.inMinutes < 60) return 'Last seen ${diff.inMinutes}m ago';
    if (diff.inHours < 24) return 'Last seen ${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Last seen yesterday';
    return 'Last seen ${diff.inDays}d ago';
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
      title: FutureBuilder<String?>(
        future: profileUrlFuture,
        builder: (context, profileSnapshot) {
          return StreamBuilder<DocumentSnapshot>(
            stream: _userStatusStream(),
            builder: (context, statusSnapshot) {
              final data = statusSnapshot.data?.data() as Map<String, dynamic>?;
              final isOnline = data?['isOnline'] as bool? ?? false;
              final lastSeen = data?['lastSeen'] as Timestamp?;
              final username = data?['username'] as String?;

              final statusText = isOnline
                  ? 'Online'
                  : _formatLastSeen(lastSeen);

              return GestureDetector(
                onTap: onTap,
                behavior: HitTestBehavior.opaque,
                child: Row(
                  children: [
                    // Avatar with online indicator
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.4),
                              width: 2,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(21),
                            child: profileSnapshot.data != null
                                ? Image.network(
                                    profileSnapshot.data!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        _defaultAvatar(),
                                  )
                                : _defaultAvatar(),
                          ),
                        ),
                        // Online dot
                        Positioned(
                          right: -1,
                          bottom: -1,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 13,
                            height: 13,
                            decoration: BoxDecoration(
                              color: isOnline
                                  ? const Color(0xFF00E676)
                                  : Colors.grey.shade400,
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),

                    // Name + status
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            username ?? otherParticipantEmail,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15.5,
                              letterSpacing: 0.1,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              if (isOnline)
                                Container(
                                  width: 6,
                                  height: 6,
                                  margin: const EdgeInsets.only(right: 5),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF00E676),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              Text(
                                statusText,
                                style: TextStyle(
                                  color: isOnline
                                      ? const Color(0xFF00E676)
                                      : Colors.white.withOpacity(0.7),
                                  fontSize: 12,
                                  fontWeight: isOnline
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.videocam_rounded,
              color: Colors.white, size: 24),
          onPressed: () {}, // Extend as needed
          tooltip: 'Video Call',
        ),
        IconButton(
          icon: const Icon(Icons.more_vert_rounded,
              color: Colors.white, size: 22),
          onPressed: () {},
          tooltip: 'More options',
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _defaultAvatar() {
    return Container(
      color: Colors.blue.shade300,
      child: const Icon(Icons.person_rounded, color: Colors.white, size: 24),
    );
  }
}