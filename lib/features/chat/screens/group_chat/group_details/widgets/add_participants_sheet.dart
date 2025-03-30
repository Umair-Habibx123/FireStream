import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddParticipantsSheet extends StatefulWidget {
  final List<Map<String, dynamic>> userList;
  final Function(List<String>, List<String>) onSave;

  const AddParticipantsSheet({
    super.key,
    required this.userList,
    required this.onSave,
  });

  @override
  _AddParticipantsSheetState createState() => _AddParticipantsSheetState();
}

class _AddParticipantsSheetState extends State<AddParticipantsSheet> {
  late List<Map<String, dynamic>> _userList;
  String _currentUserEmail = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _userList = List.from(widget.userList);
    _loadCurrentUserEmail();
  }

  Future<void> _loadCurrentUserEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUserEmail = prefs.getString('userEmail') ?? '';
      _isLoading = false;
    });
  }

  Future<bool> _isBlocked(String email) async {
    // Check if current user is blocked by the target user
    final targetUserBlocklist = await FirebaseFirestore.instance
        .collection('users')
        .doc(email)
        .collection('contacts')
        .doc('blockList')
        .get();

    if (targetUserBlocklist.exists && 
        (targetUserBlocklist.data()?['contactEmails'] as List?)?.contains(_currentUserEmail) == true) {
      return true;
    }

    // Check if target user is in current user's blocklist
    final currentUserBlocklist = await FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUserEmail)
        .collection('contacts')
        .doc('blockList')
        .get();

    if (currentUserBlocklist.exists && 
        (currentUserBlocklist.data()?['contactEmails'] as List?)?.contains(email) == true) {
      return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[900] : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Manage Participants",
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Select or deselect participants",
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          _isLoading
              ? const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              : Expanded(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _userList.length,
                    itemBuilder: (context, index) {
                      final user = _userList[index];
                      final isBlocked = user['isBlocked'] ?? false;

                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.grey[800] : Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: isBlocked
                            ? ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                                leading: user['profilePic'].isNotEmpty
                                    ? CircleAvatar(
                                        backgroundImage: NetworkImage(user['profilePic']),
                                        radius: 20,
                                      )
                                    : CircleAvatar(
                                        radius: 20,
                                        child: Icon(
                                          Icons.person,
                                          color: theme.colorScheme.onSurface,
                                        ),
                                      ),
                                title: Text(
                                  user['username'],
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey,
                                  ),
                                ),
                                subtitle: Text(
                                  'Blocked user',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.red,
                                  ),
                                ),
                                trailing: const Icon(Icons.block, color: Colors.red),
                              )
                            : CheckboxListTile(
                                value: user['isSelected'],
                                onChanged: (bool? value) {
                                  setState(() {
                                    user['isSelected'] = value ?? false;
                                  });
                                },
                                activeColor: theme.colorScheme.primary,
                                checkColor: theme.colorScheme.onPrimary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                                title: Row(
                                  children: [
                                    user['profilePic'].isNotEmpty
                                        ? CircleAvatar(
                                            backgroundImage: NetworkImage(user['profilePic']),
                                            radius: 20,
                                          )
                                        : CircleAvatar(
                                            radius: 20,
                                            child: Icon(
                                              Icons.person,
                                              color: theme.colorScheme.onSurface,
                                            ),
                                          ),
                                    const SizedBox(width: 16),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          user['username'],
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          user['email'],
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                      );
                    },
                    separatorBuilder: (context, index) => const SizedBox(height: 4),
                  ),
                ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                List<String> selectedEmails = _userList
                    .where((user) => user['isSelected'] && !(user['isBlocked'] ?? false))
                    .map((user) => user['email'] as String)
                    .toList();

                List<String> deselectedEmails = _userList
                    .where((user) => !user['isSelected'])
                    .map((user) => user['email'] as String)
                    .toList();

                widget.onSave(selectedEmails, deselectedEmails);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: theme.colorScheme.primary,
              ),
              child: Text(
                "Save Changes",
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}