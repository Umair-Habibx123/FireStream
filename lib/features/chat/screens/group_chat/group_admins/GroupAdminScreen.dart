import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminsScreen extends StatefulWidget {
  final String chatId;

  const AdminsScreen({super.key, required this.chatId});

  @override
  _AdminsScreenState createState() => _AdminsScreenState();
}

class _AdminsScreenState extends State<AdminsScreen> {
  List<String> participants = [];
  List<String> admins = []; // Assuming admins are also stored in Firestore
  bool isLoading = true;
  String? errorMessage;
  String? currentUserEmail;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserEmail();
    _loadAdmins();
  }

  // Load current user's email from shared preferences
  Future<void> _loadCurrentUserEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      currentUserEmail = prefs.getString(
        'userEmail',
      ); // Adjust the key if necessary
    });
  }

  // Load participants and admins from Firestore
  Future<void> _loadAdmins() async {
    try {
      DocumentSnapshot chatDoc =
          await FirebaseFirestore.instance
              .collection('groupChats')
              .doc(widget.chatId)
              .get();
      List<String> adminsEmails = List<String>.from(chatDoc['admins'] ?? []);
      admins = List<String>.from(chatDoc['admins'] ?? []); // Load admins

      setState(() {
        participants = adminsEmails;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = "Failed to load Admins: ${e.toString()}";
        isLoading = false;
      });
    }
  }

  // Function to delete a participant
  Future<void> _deleteParticipant(String email) async {
    try {
      await FirebaseFirestore.instance
          .collection('groupChats')
          .doc(widget.chatId)
          .update({
            'admins': FieldValue.arrayRemove([email]),
          });

      setState(() {
        participants.remove(email);
      });

      // Check for admins
      if (!admins.contains(email)) {
        // If the deleted email is not an admin, check for remaining admins
        if (admins.isEmpty) {
          // If no admins left, assign a random user as admin if there are still participants
          if (participants.isNotEmpty) {
            String newAdmin =
                participants[0]; // Assign first participant as new admin
            await _assignNewAdmin(newAdmin);
          } else {
            // If no participants left, delete the group
            await _deleteGroup();
          }
        }
      }
    } catch (e) {
      setState(() {
        errorMessage = "Failed to delete admins: ${e.toString()}";
      });
    }
  }

  // Function to assign a new admin
  Future<void> _assignNewAdmin(String email) async {
    try {
      await FirebaseFirestore.instance
          .collection('groupChats')
          .doc(widget.chatId)
          .update({
            'admins': FieldValue.arrayUnion([email]),
          });
    } catch (e) {
      setState(() {
        errorMessage = "Failed to assign new admin: ${e.toString()}";
      });
    }
  }

  // Function to delete the group
  Future<void> _deleteGroup() async {
    try {
      await FirebaseFirestore.instance
          .collection('groupChats')
          .doc(widget.chatId)
          .delete();
      Navigator.of(context).pop(); // Navigate back after deletion
    } catch (e) {
      setState(() {
        errorMessage = "Failed to delete group: ${e.toString()}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final cardColor = isDarkMode ? Colors.grey[800] : Colors.grey[50];
    final errorColor = isDarkMode ? Colors.red[300] : Colors.red;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Group Admins"),
        centerTitle: true,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
      ),
      body:
          isLoading
              ? Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.primary,
                  ),
                ),
              )
              : errorMessage != null
              ? Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: errorColor?.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    errorMessage!,
                    style: TextStyle(
                      color: errorColor,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
              : Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: ListView.separated(
                  itemCount: participants.length,
                  separatorBuilder:
                      (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    return FutureBuilder<DocumentSnapshot>(
                      future:
                          FirebaseFirestore.instance
                              .collection('users')
                              .doc(participants[index])
                              .get(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 120,
                                        height: 16,
                                        color: theme.colorScheme.onSurface
                                            .withOpacity(0.1),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        if (!snapshot.hasData || !snapshot.data!.exists) {
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  "User not found",
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        var userData = snapshot.data!;
                        var profilePhotoUrl = userData['profilePic'] ?? '';
                        final isCurrentUser =
                            participants[index] == currentUserEmail;

                        return Container(
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              if (!isDarkMode)
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading: CircleAvatar(
                              radius: 22,
                              backgroundImage:
                                  profilePhotoUrl.isNotEmpty
                                      ? NetworkImage(profilePhotoUrl)
                                          as ImageProvider
                                      : const AssetImage(
                                        'assets/placeholder_image.png',
                                      ),
                              backgroundColor: theme.colorScheme.primary
                                  .withOpacity(0.1),
                            ),
                            title: Text(
                              userData['username'] ?? participants[index],
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              participants[index],
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.6,
                                ),
                              ),
                            ),
                            trailing:
                                isCurrentUser
                                    ? Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        "You",
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                              color: theme.colorScheme.primary,
                                            ),
                                      ),
                                    )
                                    : IconButton(
                                      icon: Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.delete_outline,
                                          color: Colors.red,
                                          size: 20,
                                        ),
                                      ),
                                      onPressed: () {
                                        _deleteParticipant(participants[index]);
                                      },
                                    ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
    );
  }
}
