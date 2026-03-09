import 'package:flutter/material.dart';

class ParticipantOptionsSheet extends StatelessWidget {
  final String email;
  final bool isAdmin;
  final bool isCurrentUser;
  final bool isCurrentUserAdmin;
  final VoidCallback onMessagePressed;
  final VoidCallback onRemoveAdminPressed;
  final VoidCallback onMakeAdminPressed;
  final VoidCallback onDeletePressed;
  final VoidCallback onRemoveSelfPressed;

  const ParticipantOptionsSheet({
    super.key,
    required this.email,
    required this.isAdmin,
    required this.isCurrentUser,
    required this.isCurrentUserAdmin,
    required this.onMessagePressed,
    required this.onRemoveAdminPressed,
    required this.onMakeAdminPressed,
    required this.onDeletePressed,
    required this.onRemoveSelfPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1565C0).withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_rounded,
                      color: Color(0xFF1565C0), size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isCurrentUser ? 'Your Options' : 'Participant',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      if (!isCurrentUser)
                        Text(
                          email,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade500),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                if (isAdmin)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFA000).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Admin',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFFE65100),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const Divider(height: 1, indent: 20, endIndent: 20),
          const SizedBox(height: 8),

          // Actions
          if (isCurrentUser)
            _tile(
              icon: Icons.logout_rounded,
              label: 'Leave Group',
              subtitle: 'Remove yourself from this group',
              color: Colors.red,
              onTap: onRemoveSelfPressed,
            ),

          if (!isCurrentUser) ...[
            _tile(
              icon: Icons.message_rounded,
              label: 'Send Message',
              subtitle: 'Start a private conversation',
              color: const Color(0xFF1565C0),
              onTap: onMessagePressed,
            ),
            if (isCurrentUserAdmin && isAdmin)
              _tile(
                icon: Icons.remove_moderator_rounded,
                label: 'Remove Admin',
                subtitle: 'Revoke admin privileges',
                color: Colors.orange.shade700,
                onTap: onRemoveAdminPressed,
              ),
            if (isCurrentUserAdmin && !isAdmin)
              _tile(
                icon: Icons.admin_panel_settings_rounded,
                label: 'Make Admin',
                subtitle: 'Grant admin privileges',
                color: Colors.green.shade700,
                onTap: onMakeAdminPressed,
              ),
            if (isCurrentUserAdmin)
              _tile(
                icon: Icons.person_remove_rounded,
                label: 'Remove from Group',
                subtitle: 'Remove this participant',
                color: Colors.red,
                onTap: onDeletePressed,
              ),
          ],

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _tile({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: label.contains('Remove') ||
                                label.contains('Leave')
                            ? const Color(0xFFE53935)
                            : const Color(0xFF1A1A2E),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: Colors.grey.shade300, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}