import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class ImagePreviewScreen extends StatelessWidget {
  final String imageUrl;

  const ImagePreviewScreen({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.more_vert_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            onPressed: () => _showImageOptions(context),
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          PhotoView(
            imageProvider: NetworkImage(imageUrl),
            backgroundDecoration: const BoxDecoration(color: Colors.black),
            loadingBuilder:
                (context, event) => Center(
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      value:
                          event == null || event.expectedTotalBytes == null
                              ? null
                              : event.cumulativeBytesLoaded /
                                  event.expectedTotalBytes!,
                      strokeWidth: 3,
                      color: Colors.white,
                    ),
                  ),
                ),
            errorBuilder:
                (context, error, stackTrace) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.broken_image_outlined,
                        size: 48,
                        color: Colors.white54,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load image',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
          ),
          Positioned(
            bottom: 24,
            right: 24,
            child: FloatingActionButton(
              backgroundColor: Colors.black.withOpacity(0.5),
              onPressed: () => _shareImage(context),
              child: const Icon(Icons.share, color: Colors.white),
            ),
          ),
          Positioned(
            bottom: 24,
            left: 24,
            child: FloatingActionButton(
              backgroundColor: Colors.black.withOpacity(0.5),
              onPressed: () => _saveImage(context),
              child: const Icon(Icons.download, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showImageOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.download, color: Colors.white),
              title: const Text('Save to device', 
                style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _saveImage(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share, color: Colors.white),
              title: const Text('Share', 
                style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _shareImage(context);
              },
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', 
                style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _saveImage(BuildContext context) {
    // Implement image saving logic
  }

  void _shareImage(BuildContext context) {
    // Implement image sharing logic
  }
}