import 'package:flutter/material.dart';

class GroupImageBubble extends StatelessWidget {
  final List<dynamic> imageUrls;
  final bool isSentByCurrentUser;
  final Function(String)? onImageTap;

  const GroupImageBubble({
    super.key,
    required this.imageUrls,
    required this.isSentByCurrentUser,
    this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
        left: isSentByCurrentUser ? 40 : 8,
        right: isSentByCurrentUser ? 8 : 40,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: List.generate(
            imageUrls.length,
            (index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      color: Colors.grey.shade100,
                      child: Image.network(
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
                            size: 32,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => onImageTap?.call(imageUrls[index]),
                          borderRadius: BorderRadius.circular(12),
                          splashColor: Colors.white.withOpacity(0.2),
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
    );
  }
}