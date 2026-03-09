import 'package:flutter/material.dart';

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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Add to contacts
          FutureBuilder<bool>(
            future: isContactSavedFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _loadingButton();
              }
              final isSaved = snapshot.data == true;
              return _actionTile(
                icon: isSaved
                    ? Icons.check_circle_rounded
                    : Icons.person_add_rounded,
                label: isSaved ? 'Added to Contacts' : 'Add to Contacts',
                color: isSaved ? Colors.grey : const Color(0xFF1565C0),
                onTap: isSaved ? null : onAddToContacts,
              );
            },
          ),
          const SizedBox(height: 10),

          // Add to group
          _actionTile(
            icon: Icons.group_add_rounded,
            label: 'Add to Group',
            color: Colors.teal.shade600,
            onTap: onAddToGroup,
          ),
          const SizedBox(height: 10),

          // Block
          _actionTile(
            icon: Icons.block_rounded,
            label: 'Block User',
            color: const Color(0xFFE53935),
            onTap: onAddToBlockList,
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onTap,
    bool isDestructive = false,
  }) {
    final isDisabled = onTap == null;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        splashColor: color.withOpacity(0.08),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDestructive
                  ? Colors.red.shade100
                  : isDisabled
                      ? Colors.grey.shade200
                      : Colors.blue.shade100,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(isDisabled ? 0.06 : 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon,
                    size: 20,
                    color: isDisabled ? Colors.grey.shade400 : color),
              ),
              const SizedBox(width: 14),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDisabled
                      ? Colors.grey.shade400
                      : isDestructive
                          ? const Color(0xFFE53935)
                          : const Color(0xFF1A1A2E),
                ),
              ),
              const Spacer(),
              if (!isDisabled)
                Icon(Icons.chevron_right_rounded,
                    size: 20, color: Colors.grey.shade300),
            ],
          ),
        ),
      ),
    );
  }

  Widget _loadingButton() {
    return Container(
      width: double.infinity,
      height: 72,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: const Color(0xFF1565C0).withOpacity(0.5),
          ),
        ),
      ),
    );
  }
}