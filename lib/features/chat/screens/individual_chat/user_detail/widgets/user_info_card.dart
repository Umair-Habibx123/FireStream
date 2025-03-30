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
      margin: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade100.withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        elevation: 0,
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.blue.shade200, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.shade100.withOpacity(0.4),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: GestureDetector(
                  onTap: () => onImageTap(profileUrl),
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.blue.shade50,
                    backgroundImage: NetworkImage(profileUrl),
                    child:
                        profileUrl.isEmpty
                            ? Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.blue.shade300,
                            )
                            : null,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                username,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade800,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  email,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.blue.shade700,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
