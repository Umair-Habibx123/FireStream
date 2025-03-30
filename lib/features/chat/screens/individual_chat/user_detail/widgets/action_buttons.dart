import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class ActionButtons extends StatelessWidget {
  final String email;
  final String currentUserEmail;
  final VoidCallback onAddToContacts;
  final VoidCallback onAddToBlockList;
  final VoidCallback onAddToGroup;
  final Future<bool> isContactSavedFuture;

  const ActionButtons({
    super.key,
    required this.email,
    required this.currentUserEmail,
    required this.onAddToContacts,
    required this.onAddToBlockList,
    required this.onAddToGroup,
    required this.isContactSavedFuture,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          // Add to Group Button
          Material(
            borderRadius: BorderRadius.circular(30),
            elevation: 0,
            child: InkWell(
              borderRadius: BorderRadius.circular(30),
              onTap: onAddToGroup,
              child: Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.teal.shade400, Colors.teal.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.teal.shade200.withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.group_add, size: 22, color: Colors.white),
                    const SizedBox(width: 12),
                    Text(
                      "Add to Group",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Add to Contacts Button
          FutureBuilder<bool>(
            future: isContactSavedFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.blue.shade400,
                      ),
                    ),
                  ),
                );
              }
              if (snapshot.data == true) {
                return Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check, size: 22, color: Colors.white),
                      const SizedBox(width: 12),
                      Text(
                        "Added to Contacts",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                );
              } else {
                return Material(
                  borderRadius: BorderRadius.circular(30),
                  elevation: 0,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(30),
                    onTap: onAddToContacts,
                    child: Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade400, Colors.blue.shade600],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.shade200.withOpacity(0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_add, size: 22, color: Colors.white),
                          const SizedBox(width: 12),
                          Text(
                            "Add to Contacts",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 16),

          // Block Button
          Material(
            borderRadius: BorderRadius.circular(30),
            elevation: 0,
            child: InkWell(
              borderRadius: BorderRadius.circular(30),
              onTap: onAddToBlockList,
              child: Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red.shade400, Colors.red.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.shade200.withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.block, size: 22, color: Colors.white),
                    const SizedBox(width: 12),
                    Text(
                      "Block User",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
