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
    if (imageUrls.isEmpty) return const SizedBox.shrink();

    if (imageUrls.length == 1) {
      return _buildSingleImage(context, imageUrls[0]);
    }

    return _buildImageGrid(context);
  }

  Widget _buildSingleImage(BuildContext context, String url) {
    return GestureDetector(
      onTap: () => onImageTap?.call(url),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.58,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: _networkImage(url, width: null, height: 180),
        ),
      ),
    );
  }

  Widget _buildImageGrid(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width * 0.58;
    final itemSize = (maxWidth - 4) / 2;
    final showCount = imageUrls.length > 4 ? 4 : imageUrls.length;
    final extraCount = imageUrls.length - 4;

    return SizedBox(
      width: maxWidth,
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: List.generate(showCount, (i) {
          final isLast = i == 3 && extraCount > 0;
          return GestureDetector(
            onTap: () => onImageTap?.call(imageUrls[i]),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: itemSize,
                height: itemSize,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _networkImage(imageUrls[i],
                        width: itemSize, height: itemSize),
                    if (isLast)
                      Container(
                        color: Colors.black.withOpacity(0.52),
                        child: Center(
                          child: Text(
                            '+$extraCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _networkImage(String url,
      {required double? width, required double? height}) {
    return Image.network(
      url,
      width: width,
      height: height,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: width,
          height: height ?? 180,
          color: Colors.grey.shade100,
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      (loadingProgress.expectedTotalBytes ?? 1)
                  : null,
              strokeWidth: 2,
              color: const Color(0xFF1565C0),
            ),
          ),
        );
      },
      errorBuilder: (_, __, ___) => Container(
        width: width,
        height: height ?? 180,
        color: Colors.grey.shade100,
        child: Icon(Icons.broken_image_outlined,
            size: 30, color: Colors.grey.shade400),
      ),
    );
  }
}