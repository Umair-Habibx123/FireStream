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
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          _buildSection('Account', [
            _buildTile(
              context,
              icon: Icons.person_outline_rounded,
              label: 'Edit Username',
              color: Colors.blueAccent,
              onTap: () => _showUsernameDialog(context),
            ),
            _buildTile(
              context,
              icon: Icons.lock_outline_rounded,
              label: 'Change Password',
              color: Colors.purple,
              onTap: onUpdatePassword,
            ),
          ]),
          _buildSection('Privacy', [
            _buildTile(
              context,
              icon: Icons.people_outline_rounded,
              label: 'Manage Contacts',
              color: Colors.teal,
              onTap: onEditContacts,
            ),
            _buildTile(
              context,
              icon: Icons.block_rounded,
              label: 'Blocked Users',
              color: Colors.orange,
              onTap: onEditBlocklist,
            ),
          ]),
          _buildSection('Session', [
            _buildTile(
              context,
              icon: Icons.logout_rounded,
              label: 'Log Out',
              color: Colors.red,
              isDestructive: true,
              onTap: onLogout,
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> tiles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20, top: 20, bottom: 6),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade400,
              letterSpacing: 1.2,
            ),
          ),
        ),
        ...tiles,
      ],
    );
  }

  Widget _buildTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: color.withOpacity(0.08),
        highlightColor: color.withOpacity(0.04),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 19, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: isDestructive
                        ? Colors.red
                        : const Color(0xFF1A1A2E),
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  size: 20, color: Colors.grey.shade300),
            ],
          ),
        ),
      ),
    );
  }

  void _showUsernameDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.person_outline_rounded,
                        color: Colors.blueAccent, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Edit Username',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: usernameController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'New Username',
                  labelStyle: TextStyle(color: Colors.grey.shade500),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: Colors.blueAccent, width: 1.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: Colors.grey.shade200, width: 1),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: Text('Cancel',
                          style: TextStyle(color: Colors.grey.shade600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 13),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        onUpdateUsername();
                        Navigator.of(ctx).pop();
                      },
                      child: const Text('Update',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
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