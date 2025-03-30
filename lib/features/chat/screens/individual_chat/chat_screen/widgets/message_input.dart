import 'package:flutter/material.dart';
import 'dart:io';

class MessageInput extends StatelessWidget {
  final TextEditingController messageController;
  final List<File> selectedImages;
  final bool isUploading;
  final VoidCallback onPickImages;
  final Function(int) onRemoveImage;
  final VoidCallback onSendMessage;

  const MessageInput({
    super.key,
    required this.messageController,
    required this.selectedImages,
    required this.isUploading,
    required this.onPickImages,
    required this.onRemoveImage,
    required this.onSendMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          if (selectedImages.isNotEmpty)
            Container(
              height: 120,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: selectedImages.length,
                itemBuilder: (context, index) => Container(
                  margin: const EdgeInsets.only(right: 12),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          selectedImages[index],
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => onRemoveImage(index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (isUploading)
            LinearProgressIndicator(
              minHeight: 2,
              backgroundColor: Colors.blue.shade50,
              color: Colors.blueAccent,
            ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.photo_library_outlined,
                      color: Colors.blueAccent,
                    ),
                    onPressed: onPickImages,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: messageController,
                            decoration: const InputDecoration(
                              hintText: 'Type a message...',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                            maxLines: 5,
                            minLines: 1,
                            onSubmitted: (value) => onSendMessage(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: !isUploading
                                ? Colors.blueAccent
                                : Colors.grey.shade300,
                            shape: BoxShape.circle,
                          ),
                          margin: const EdgeInsets.only(right: 4),
                          child: IconButton(
                            icon: Icon(
                              Icons.send,
                              color: !isUploading
                                  ? Colors.white
                                  : Colors.grey.shade500,
                            ),
                            onPressed: !isUploading ? onSendMessage : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}