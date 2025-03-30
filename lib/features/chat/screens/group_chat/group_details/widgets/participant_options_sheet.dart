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
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final cardColor = isDarkMode ? Colors.grey[800] : Colors.grey[50];

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[900] : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 48,
            height: 4,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                  child: Icon(Icons.person, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isCurrentUser ? "Your Options" : "Participant Options",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (!isCurrentUser) Text(
                        email,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Options
          Flexible(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isCurrentUser)
                    _buildModernOptionTile(
                      context,
                      icon: Icons.logout_rounded,
                      label: "Leave Group",
                      description: "Remove yourself from this group",
                      color: Colors.red,
                      onTap: onRemoveSelfPressed,
                    ),
                  if (!isCurrentUser)
                    _buildModernOptionTile(
                      context,
                      icon: Icons.message_rounded,
                      label: "Send Message",
                      description: "Start a private conversation",
                      color: Colors.blue,
                      onTap: onMessagePressed,
                    ),
                  if (!isCurrentUser && isCurrentUserAdmin && isAdmin)
                    _buildModernOptionTile(
                      context,
                      icon: Icons.admin_panel_settings_rounded,
                      label: "Remove Admin",
                      description: "Revoke admin privileges",
                      color: Colors.orange,
                      onTap: onRemoveAdminPressed,
                    ),
                  if (!isCurrentUser && isCurrentUserAdmin && !isAdmin)
                    _buildModernOptionTile(
                      context,
                      icon: Icons.admin_panel_settings_rounded,
                      label: "Make Admin",
                      description: "Grant admin privileges",
                      color: Colors.green,
                      onTap: onMakeAdminPressed,
                    ),
                  if (!isCurrentUser && isCurrentUserAdmin)
                    _buildModernOptionTile(
                      context,
                      icon: Icons.person_remove_rounded,
                      label: "Remove Participant",
                      description: "Remove from this group",
                      color: Colors.red,
                      onTap: onDeletePressed,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildModernOptionTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurface.withOpacity(0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}