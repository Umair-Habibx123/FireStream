import 'package:flutter/material.dart';

class UserInfoCard extends StatelessWidget {
  final String profileUrl;
  final String username;
  final String email;
  final Function(String) onImageTap;

  const UserInfoCard({
    super.key,
    required this.profileUrl,
    required this.username,
    required this.email,
    required this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [const Color(0xFF1565C0), Colors.blue.shade600],
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 32),

          // Avatar
          GestureDetector(
            onTap: profileUrl.isNotEmpty ? () => onImageTap(profileUrl) : null,
            child: Hero(
              tag: 'profile-image',
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 54,
                      backgroundColor: Colors.blue.shade300,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(54),
                        child: profileUrl.isNotEmpty
                            ? Image.network(
                                profileUrl,
                                width: 108,
                                height: 108,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _defaultAvatarContent(),
                              )
                            : _defaultAvatarContent(),
                      ),
                    ),
                  ),
                  if (profileUrl.isNotEmpty)
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Icon(Icons.zoom_in_rounded,
                            size: 14, color: Colors.blue.shade600),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Username
          Text(
            username,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Email chip
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              email,
              style: const TextStyle(
                fontSize: 13.5,
                color: Colors.white,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }

  Widget _defaultAvatarContent() {
    return const Icon(Icons.person_rounded, size: 54, color: Colors.white);
  }
}