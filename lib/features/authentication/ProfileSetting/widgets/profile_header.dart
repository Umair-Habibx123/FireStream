import 'package:flutter/material.dart';

class ProfileHeader extends StatelessWidget {
  final String photoURL;
  final String username;
  final String email;
  final VoidCallback onEditPhoto;
  final bool isLoading;

  const ProfileHeader({
    super.key,
    required this.photoURL,
    required this.username,
    required this.email,
    required this.onEditPhoto,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.blue.shade200, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.shade100.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(60),
                child:
                    isLoading
                        ? Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.blueAccent,
                          ),
                        )
                        : photoURL.isNotEmpty
                        ? Image.network(
                          photoURL,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value:
                                    loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            (loadingProgress
                                                    .expectedTotalBytes ??
                                                1)
                                        : null,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.person,
                              size: 48,
                              color: Colors.blue.shade300,
                            );
                          },
                        )
                        : Icon(
                          Icons.person,
                          size: 48,
                          color: Colors.blue.shade300,
                        ),
              ),
            ),
            // In the ProfileHeader widget's Stack
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: isLoading ? null : onEditPhoto,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isLoading ? Colors.grey : Colors.blueAccent,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child:
                      isLoading
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : const Icon(
                            Icons.edit,
                            size: 20,
                            color: Colors.white,
                          ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          username,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            email,
            style: TextStyle(fontSize: 16, color: Colors.blue.shade700),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
