import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:chat_app/features/services/audio_recorder_service.dart';

class GroupMessageInput extends StatefulWidget {
  final TextEditingController messageController;
  final bool canSendMessages;
  final bool isUploading;
  final VoidCallback onSendPressed;
  final VoidCallback onPickImagesPressed;
  final List<File> selectedImages;
  final Function(int) onRemoveImage;
  final Function(String path)? onSendAudio;
  final VoidCallback? onSchedule;

  const GroupMessageInput({
    super.key,
    required this.messageController,
    required this.canSendMessages,
    required this.isUploading,
    required this.onSendPressed,
    required this.onPickImagesPressed,
    required this.selectedImages,
    required this.onRemoveImage,
    this.onSendAudio,
    this.onSchedule,
  });

  @override
  State<GroupMessageInput> createState() => _GroupMessageInputState();
}

class _GroupMessageInputState extends State<GroupMessageInput> {
  bool _hasText = false;
  final AudioRecorderService _recorder = AudioRecorderService();
  bool _isRecording = false;
  Duration _recordElapsed = Duration.zero;
  Timer? _recordTimer;

  @override
  void initState() {
    super.initState();
    widget.messageController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.messageController.removeListener(_onTextChanged);
    _recordTimer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = widget.messageController.text.trim().isNotEmpty;
    if (hasText != _hasText) setState(() => _hasText = hasText);
  }

  Future<void> _startRecording() async {
    final error = await _recorder.start();
    if (error != null) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error)));
      }
      return;
    }
    setState(() => _isRecording = true);
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _recordElapsed = _recorder.elapsed);
    });
  }

  Future<void> _stopAndSend() async {
    _recordTimer?.cancel();
    final path = await _recorder.stop();
    setState(() {
      _isRecording = false;
      _recordElapsed = Duration.zero;
    });
    if (path != null) widget.onSendAudio?.call(path);
  }

  Future<void> _cancelRecording() async {
    _recordTimer?.cancel();
    await _recorder.cancel();
    setState(() {
      _isRecording = false;
      _recordElapsed = Duration.zero;
    });
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final fieldBg = Theme.of(context).brightness == Brightness.dark
        ? Colors.white10
        : const Color(0xFFF2F4F7);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
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
          if (widget.isUploading)
            SizedBox(
              height: 2,
              child: LinearProgressIndicator(
                backgroundColor: primary.withOpacity(0.15),
                color: primary,
              ),
            ),

          if (!widget.canSendMessages)
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              color: Colors.orange.withOpacity(0.12),
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

          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: _isRecording
                  ? _recordingRow(primary)
                  : _inputRow(primary, fieldBg),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputRow(Color primary, Color fieldBg) {
    final enabled = widget.canSendMessages;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Attach
        GestureDetector(
          onTap: enabled ? widget.onPickImagesPressed : null,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: enabled
                  ? primary.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.add_rounded,
                size: 22, color: enabled ? primary : Colors.grey),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            constraints: const BoxConstraints(maxHeight: 120),
            decoration: BoxDecoration(
              color: fieldBg,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: widget.messageController,
                    maxLines: 5,
                    minLines: 1,
                    enabled: enabled,
                    textCapitalization: TextCapitalization.sentences,
                    style: TextStyle(
                      fontSize: 15,
                      color: Theme.of(context).colorScheme.onSurface,
                      height: 1.4,
                    ),
                    decoration: InputDecoration(
                      hintText: enabled
                          ? 'Message...'
                          : 'Only admins can send messages',
                      hintStyle:
                          TextStyle(color: Colors.grey.shade400, fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                if (enabled && widget.onSchedule != null)
                  IconButton(
                    tooltip: 'Schedule message',
                    icon: Icon(Icons.schedule_rounded,
                        color: primary.withOpacity(0.8), size: 22),
                    onPressed: widget.onSchedule,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, anim) =>
              ScaleTransition(scale: anim, child: child),
          child: (_hasText || widget.selectedImages.isNotEmpty) && enabled
              ? _sendButton(primary)
              : _micButton(primary, enabled),
        ),
      ],
    );
  }

  Widget _recordingRow(Color primary) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
          onPressed: _cancelRecording,
          tooltip: 'Cancel',
        ),
        const SizedBox(width: 4),
        Container(
          width: 12,
          height: 12,
          decoration:
              const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Text(_fmt(_recordElapsed),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const Spacer(),
        const Text('Recording...', style: TextStyle(color: Colors.grey)),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: _stopAndSend,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: primary, shape: BoxShape.circle),
            child:
                const Icon(Icons.send_rounded, color: Colors.white, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _sendButton(Color primary) {
    return GestureDetector(
      key: const ValueKey('send'),
      onTap: widget.isUploading ? null : widget.onSendPressed,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: widget.isUploading ? Colors.grey.shade300 : primary,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _micButton(Color primary, bool enabled) {
    return GestureDetector(
      key: const ValueKey('mic'),
      onTap: enabled ? _startRecording : null,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: enabled
              ? primary.withOpacity(0.1)
              : Colors.grey.withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.mic_rounded,
            color: enabled ? primary : Colors.grey, size: 22),
      ),
    );
  }
}
