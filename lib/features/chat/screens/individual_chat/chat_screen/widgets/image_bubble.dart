import 'package:flutter/material.dart';

class ImageBubble extends StatelessWidget {
  final List<dynamic> imageUrls;
  final Function(String) onImageTap;

  const ImageBubble({
    super.key,
    required this.imageUrls,
    required this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          imageUrls.length,
          (index) => GestureDetector(
            onTap: () => onImageTap(imageUrls[index]),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 6.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 6,
                    spreadRadius: 1,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 120,
                  height: 120,
                  color: Colors.grey.shade100,
                  child: Stack(
                    children: [
                      Image.network(
                        imageUrls[index],
                        width: 120,
                        height: 120,
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
                        errorBuilder: (context, error, stackTrace) => Center(
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            size: 40,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => onImageTap(imageUrls[index]),
                            splashColor: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}