import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:chat_app/features/services/audio_recorder_service.dart';

class MessageInput extends StatefulWidget {
  final TextEditingController messageController;
  final List<File> selectedImages;
  final bool isUploading;
  final VoidCallback onPickImages;
  final Function(int) onRemoveImage;
  final VoidCallback onSendMessage;

  /// Called with the recorded audio file path when a voice note is finished.
  final Function(String path)? onSendAudio;

  /// Called when the user taps the "schedule" (clock) button.
  final VoidCallback? onSchedule;

  const MessageInput({
    super.key,
    required this.messageController,
    required this.selectedImages,
    required this.isUploading,
    required this.onPickImages,
    required this.onRemoveImage,
    required this.onSendMessage,
    this.onSendAudio,
    this.onSchedule,
  });

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
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
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  Future<void> _startRecording() async {
    final error = await _recorder.start();
    if (error != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
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
    final theme = Theme.of(context);
    final surface = theme.cardColor;
    final primary = theme.colorScheme.primary;
    final fieldBg = theme.brightness == Brightness.dark
        ? Colors.white10
        : const Color(0xFFF2F4F7);

    return Container(
      decoration: BoxDecoration(
        color: surface,
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
                  : _inputRow(primary, fieldBg, theme),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputRow(Color primary, Color fieldBg, ThemeData theme) {
    final textColor =
        theme.brightness == Brightness.dark ? Colors.white : Theme.of(context).colorScheme.onSurface;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _circleButton(
          icon: Icons.add_rounded,
          color: primary,
          onTap: widget.onPickImages,
          size: 44,
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
                    textCapitalization: TextCapitalization.sentences,
                    style: TextStyle(fontSize: 15, color: textColor, height: 1.4),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: const TextStyle(
                          color: Color(0xFFADB5BD), fontSize: 15),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                // Schedule button (clock)
                if (widget.onSchedule != null)
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
          child: _hasText || widget.selectedImages.isNotEmpty
              ? _sendButton(primary)
              : _circleButton(
                  key: const ValueKey('mic'),
                  icon: Icons.mic_rounded,
                  color: primary,
                  onTap: _startRecording,
                  size: 44,
                ),
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
        _PulsingDot(),
        const SizedBox(width: 10),
        Text(
          _fmt(_recordElapsed),
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const Spacer(),
        Text('Recording...', style: TextStyle(color: Colors.grey)),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: _stopAndSend,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: primary, shape: BoxShape.circle),
            child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _sendButton(Color primary) {
    return GestureDetector(
      key: const ValueKey('send'),
      onTap: widget.isUploading ? null : widget.onSendMessage,
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

  Widget _circleButton({
    Key? key,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required double size,
  }) {
    return GestureDetector(
      key: key,
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.3, end: 1.0).animate(_c),
      child: Container(
        width: 12,
        height: 12,
        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
      ),
    );
  }
}
