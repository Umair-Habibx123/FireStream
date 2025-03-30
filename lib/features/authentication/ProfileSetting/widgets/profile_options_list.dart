import 'package:flutter/material.dart';

class ProfileOptionsList extends StatelessWidget {
  final TextEditingController usernameController;
  final VoidCallback onUpdateUsername;
  final VoidCallback onUpdatePassword;
  final VoidCallback onEditContacts;
  final VoidCallback onEditBlocklist;
  final VoidCallback onLogout;

  const ProfileOptionsList({
    super.key,
    required this.usernameController,
    required this.onUpdateUsername,
    required this.onUpdatePassword,
    required this.onEditContacts,
    required this.onEditBlocklist,
    required this.onLogout,
  });


   @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildSettingsSection("Account Settings", [
            _buildOptionTile(
              context,
              icon: Icons.person_outline,
              title: "Edit Username",
              onTap: () => _showUsernameDialog(context),
            ),
            _buildOptionTile(
              context,
              icon: Icons.lock_outline,
              title: "Change Password",
              onTap: onUpdatePassword,
            ),
          ]),
          _buildSettingsSection("Privacy", [
            _buildOptionTile(
              context,
              icon: Icons.people_outline,
              title: "Manage Contacts",
              onTap: onEditContacts,
            ),
            _buildOptionTile(
              context,
              icon: Icons.block,
              title: "Blocked Users",
              onTap: onEditBlocklist,
            ),
          ]),
          _buildSettingsSection("Session", [
            _buildOptionTile(
              context,
              icon: Icons.logout,
              title: "Logout",
              isDestructive: true,
              onTap: onLogout,
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 24, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Colors.grey.shade200,
              width: 1,
            ),
          ),
          child: Column(
            children: options,
          ),
        ),
      ],
    );
  }

  Widget _buildOptionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? Colors.red : Colors.blueAccent;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        splashColor: color.withOpacity(0.1),
        highlightColor: color.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: color,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isDestructive ? Colors.red : Colors.grey.shade800,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: Colors.grey.shade500,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUsernameDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Edit Username",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: usernameController,
                decoration: InputDecoration(
                  labelText: 'New Username',
                  labelStyle: TextStyle(color: Colors.grey.shade600),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.blueAccent),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey.shade600,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text("Cancel"),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      onUpdateUsername();
                      Navigator.of(context).pop();
                    },
                    child: const Text("Update"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}