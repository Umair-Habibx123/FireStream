import 'dart:io';
import 'package:flutter/material.dart';

class GroupPhotoEditor extends StatelessWidget {
  final String? photoUrl;
  final bool isLoading;
  final Function() onPickPhoto;

  const GroupPhotoEditor({
    super.key,
    required this.photoUrl,
    required this.isLoading,
    required this.onPickPhoto,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPickPhoto,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1565C0).withOpacity(0.35),
                  blurRadius: 16,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(3),
            child: ClipOval(
              child: isLoading
                  ? Container(
                      color: const Color(0xFFE3F2FD),
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Color(0xFF1565C0),
                        ),
                      ),
                    )
                  : _buildPhotoContent(),
            ),
          ),
          Positioned(
            bottom: 2,
            right: 2,
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
                ),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoContent() {
    if (photoUrl == null) {
      return Container(
        color: const Color(0xFFE3F2FD),
        child: const Icon(Icons.group_rounded, size: 48, color: Color(0xFF1565C0)),
      );
    }

    return photoUrl!.startsWith('http')
        ? Image.network(
            photoUrl!,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: const Color(0xFFE3F2FD),
                child: Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            (loadingProgress.expectedTotalBytes ?? 1)
                        : null,
                    strokeWidth: 2.5,
                    color: const Color(0xFF1565C0),
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) => Container(
              color: const Color(0xFFE3F2FD),
              child: const Icon(Icons.group_rounded, size: 48, color: Color(0xFF1565C0)),
            ),
          )
        : Image.file(File(photoUrl!), fit: BoxFit.cover);
  }
}