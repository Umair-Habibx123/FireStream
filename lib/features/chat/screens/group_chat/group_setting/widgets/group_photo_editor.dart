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
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.blue.shade100,
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
              child: isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.blueAccent,
                      ),
                    )
                  : _buildPhotoContent(),
            ),
          ),
          Positioned(
            bottom: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.blueAccent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.edit,
                size: 20,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoContent() {
    if (photoUrl == null) {
      return Container(
        color: Colors.blue.shade50,
        child: Icon(
          Icons.group,
          size: 48,
          color: Colors.blue.shade400,
        ),
      );
    }

    return photoUrl!.startsWith('http')
        ? Image.network(
            photoUrl!,
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
                child: Icon(
                  Icons.error_outline,
                  size: 40,
                  color: Colors.blue.shade400,
                ),
              );
            },
          )
        : Image.file(
            File(photoUrl!),
            fit: BoxFit.cover,
          );
  }
}