import 'package:flutter/material.dart';

class ChatSettingsAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ChatSettingsAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text(
        "Group Settings",
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
      ),
      centerTitle: true,
      backgroundColor: Colors.blueAccent,
      iconTheme: const IconThemeData(color: Colors.white),
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(12),
        ),
      ),
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blueAccent,
              Colors.blue.shade700,
            ],
          ),
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(12),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 10);
}