import 'package:flutter/material.dart';

class MessageBubble extends StatelessWidget {
  final String text;
  final bool isSentByCurrentUser;
  final bool showTail;

  const MessageBubble({
    super.key,
    required this.text,
    required this.isSentByCurrentUser,
    this.showTail = true,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isSentByCurrentUser
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        margin: EdgeInsets.only(
          top: 2,
          bottom: 2,
          left: isSentByCurrentUser ? 48 : 10,
          right: isSentByCurrentUser ? 10 : 48,
        ),
        child: CustomPaint(
          painter: showTail
              ? _BubbleTailPainter(
                  isSent: isSentByCurrentUser,
                  color: isSentByCurrentUser
                      ? const Color(0xFF1565C0)
                      : Colors.white,
                )
              : null,
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: 10,
              horizontal: 14,
            ),
            decoration: BoxDecoration(
              color: isSentByCurrentUser
                  ? const Color(0xFF1565C0)
                  : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(
                    isSentByCurrentUser ? 18 : (showTail ? 4 : 18)),
                bottomRight: Radius.circular(
                    isSentByCurrentUser ? (showTail ? 4 : 18) : 18),
              ),
              boxShadow: [
                BoxShadow(
                  color: isSentByCurrentUser
                      ? const Color(0xFF1565C0).withOpacity(0.25)
                      : Colors.black.withOpacity(0.07),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Text(
              text,
              style: TextStyle(
                color: isSentByCurrentUser
                    ? Colors.white
                    : const Color(0xFF1A1A2E),
                fontSize: 15,
                height: 1.45,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Draws a small tail/pointer on the bubble
class _BubbleTailPainter extends CustomPainter {
  final bool isSent;
  final Color color;

  _BubbleTailPainter({required this.isSent, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    if (isSent) {
      // Tail on bottom-right
      path.moveTo(size.width - 4, size.height - 4);
      path.lineTo(size.width + 8, size.height + 2);
      path.lineTo(size.width - 12, size.height - 2);
    } else {
      // Tail on bottom-left
      path.moveTo(4, size.height - 4);
      path.lineTo(-8, size.height + 2);
      path.lineTo(12, size.height - 2);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_BubbleTailPainter old) =>
      old.isSent != isSent || old.color != color;
}