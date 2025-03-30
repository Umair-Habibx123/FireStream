import 'package:flutter/material.dart';

class GroupInfoHeader extends StatelessWidget {
  final String groupName;
  final String? groupPhotoUrl;
  final VoidCallback onPhotoTap;

  const GroupInfoHeader({
    super.key,
    required this.groupName,
    required this.groupPhotoUrl,
    required this.onPhotoTap,
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
                border: Border.all(
                  color: Colors.blue.shade200,
                  width: 2.5,
                ),
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
                child: groupPhotoUrl != null && groupPhotoUrl!.isNotEmpty
                    ? Image.network(
                        groupPhotoUrl!,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      (loadingProgress.expectedTotalBytes ?? 1)
                                  : null,
                              strokeWidth: 2,
                              color: Colors.blueAccent,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.blue.shade50,
                            child: const Icon(
                              Icons.group,
                              size: 48,
                              color: Colors.blueAccent,
                            ),
                          );
                        },
                      )
                    : Container(
                        color: Colors.blue.shade50,
                        child: const Icon(
                          Icons.group,
                          size: 48,
                          color: Colors.blueAccent,
                        ),
                      ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.blueAccent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.edit,
                size: 20,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          groupName,
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
            'Group',
            style: TextStyle(
              fontSize: 14,
              color: Colors.blue.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}