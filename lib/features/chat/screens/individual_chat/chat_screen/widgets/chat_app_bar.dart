import 'package:flutter/material.dart';

class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Future<String?> profileUrlFuture;
  final String otherParticipantEmail;
  final VoidCallback onTap;

  const ChatAppBar({
    super.key,
    required this.profileUrlFuture,
    required this.otherParticipantEmail,
    required this.onTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 10);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: FutureBuilder<String?>(
        future: profileUrlFuture,
        builder: (context, snapshot) {
          return Row(
            children: [
              GestureDetector(
                onTap: onTap,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: snapshot.data != null
                        ? Image.network(
                            snapshot.data!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => 
                                const Icon(Icons.person, color: Colors.white),
                          )
                        : const Icon(Icons.person, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: onTap,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        otherParticipantEmail,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16.0,
                          letterSpacing: 0.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Online', // You can make this dynamic
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      backgroundColor: Colors.blueAccent,
      iconTheme: const IconThemeData(color: Colors.white),
      elevation: 1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(12),
        ),
      ),
      toolbarHeight: kToolbarHeight + 10,
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
}