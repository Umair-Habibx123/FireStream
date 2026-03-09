import 'dart:io';
import 'package:flutter/material.dart';

class GroupMessageInput extends StatefulWidget {
  final TextEditingController messageController;
  final bool canSendMessages;
  final bool isUploading;
  final VoidCallback onSendPressed;
  final VoidCallback onPickImagesPressed;
  final List<File> selectedImages;
  final Function(int) onRemoveImage;

  const GroupMessageInput({
    super.key,
    required this.messageController,
    required this.canSendMessages,
    required this.isUploading,
    required this.onSendPressed,
    required this.onPickImagesPressed,
    required this.selectedImages,
    required this.onRemoveImage,
  });

  @override
  State<GroupMessageInput> createState() => _GroupMessageInputState();
}

class _GroupMessageInputState extends State<GroupMessageInput> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.messageController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.messageController.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = widget.messageController.text.trim().isNotEmpty;
    if (hasText != _hasText) setState(() => _hasText = hasText);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Upload progress
          if (widget.isUploading)
            SizedBox(
              height: 2,
              child: LinearProgressIndicator(
                backgroundColor: Colors.blue.shade50,
                color: const Color(0xFF1565C0),
              ),
            ),

          // Admin restriction banner
          if (!widget.canSendMessages)
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              color: Colors.orange.shade50,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline_rounded,
                      size: 14, color: Colors.orange.shade700),
                  const SizedBox(width: 6),
                  Text(
                    'Only admins can send messages',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          // Image previews
          if (widget.selectedImages.isNotEmpty)
            Container(
              height: 108,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: widget.selectedImages.length,
                itemBuilder: (context, index) => Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          widget.selectedImages[index],
                          width: 88,
                          height: 88,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => widget.onRemoveImage(index),
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: const BoxDecoration(
                              color: Colors.black87,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close,
                                size: 13, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Input row
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Attach button
                  GestureDetector(
                    onTap: widget.canSendMessages
                        ? widget.onPickImagesPressed
                        : null,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: widget.canSendMessages
                            ? const Color(0xFF1565C0).withOpacity(0.1)
                            : Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 22,
                        color: widget.canSendMessages
                            ? const Color(0xFF1565C0)
                            : Colors.grey.shade400,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Text field
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 120),
                      decoration: BoxDecoration(
                        color: widget.canSendMessages
                            ? const Color(0xFFF2F4F7)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: const Color(0xFFE4E7EC),
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: widget.messageController,
                        maxLines: 5,
                        minLines: 1,
                        enabled: widget.canSendMessages,
                        textCapitalization: TextCapitalization.sentences,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFF1A1A2E),
                          height: 1.4,
                        ),
                        decoration: InputDecoration(
                          hintText: widget.canSendMessages
                              ? 'Message...'
                              : 'Only admins can send messages',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Send / mic button
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, anim) =>
                        ScaleTransition(scale: anim, child: child),
                    child:
                        (_hasText || widget.selectedImages.isNotEmpty) &&
                                widget.canSendMessages
                            ? _sendButton()
                            : _micButton(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sendButton() {
    return GestureDetector(
      key: const ValueKey('send'),
      onTap: widget.isUploading ? null : widget.onSendPressed,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          gradient: widget.isUploading
              ? null
              : const LinearGradient(
                  colors: [Color(0xFF1976D2), Color(0xFF1565C0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          color: widget.isUploading ? Colors.grey.shade300 : null,
          shape: BoxShape.circle,
          boxShadow: widget.isUploading
              ? null
              : [
                  BoxShadow(
                    color: const Color(0xFF1565C0).withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _micButton() {
    return Container(
      key: const ValueKey('mic'),
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.mic_none_rounded,
          color: Colors.grey.shade400, size: 22),
    );
  }
}