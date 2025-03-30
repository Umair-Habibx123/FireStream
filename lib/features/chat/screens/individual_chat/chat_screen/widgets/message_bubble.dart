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
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        padding: const EdgeInsets.symmetric(
          vertical: 12.0,
          horizontal: 16.0,
        ),
        decoration: BoxDecoration(
          color: isSentByCurrentUser 
              ? Colors.blueAccent 
              : Colors.grey.shade200,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16.0),
            topRight: const Radius.circular(16.0),
            bottomLeft: isSentByCurrentUser 
                ? const Radius.circular(16.0) 
                : const Radius.circular(4.0),
            bottomRight: isSentByCurrentUser 
                ? const Radius.circular(4.0) 
                : const Radius.circular(16.0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSentByCurrentUser ? Colors.white : Colors.grey.shade800,
            fontSize: 15,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}