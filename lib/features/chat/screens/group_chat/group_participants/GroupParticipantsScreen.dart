import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ParticipantsScreen extends StatefulWidget {
  final String chatId;

  const ParticipantsScreen({super.key, required this.chatId});

  @override
  _ParticipantsScreenState createState() => _ParticipantsScreenState();
}

class _ParticipantsScreenState extends State<ParticipantsScreen> {
  List<String> participants = [];
  List<String> admins = []; // Assuming admins are also stored in Firestore
  bool isLoading = true;
  String? errorMessage;
  String? currentUserEmail;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserEmail();
    _loadParticipants();
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
  Future<void> _loadParticipants() async {
    try {
      DocumentSnapshot chatDoc =
          await FirebaseFirestore.instance
              .collection('groupChats')
              .doc(widget.chatId)
              .get();
      List<String> participantEmails = List<String>.from(
        chatDoc['participants'] ?? [],
      );
      admins = List<String>.from(chatDoc['admins'] ?? []); // Load admins

      setState(() {
        participants = participantEmails;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = "Failed to load participants: ${e.toString()}";
        isLoading = false;
      });
    }
  }

  // Function to delete a participant
  Future<void> _deleteParticipant(String email) async {
    try {
      // Check if the participant is an admin
      bool isAdmin = admins.contains(email);

      // Remove the participant from Firestore
      await FirebaseFirestore.instance
          .collection('groupChats')
          .doc(widget.chatId)
          .update({
            'participants': FieldValue.arrayRemove([email]),
          });

      // Update the local participants list
      setState(() {
        participants.remove(email);
        if (isAdmin) {
          admins.remove(email); // Remove from local admins list
        }
      });

      // If the deleted email is an admin, remove them from Firestore admin list
      if (isAdmin) {
        await _removeAdmin(email);
      }

      // Check for remaining admins
      if (!admins.contains(email)) {
        // If no admins left, check for remaining participants
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
        errorMessage = "Failed to delete participant: ${e.toString()}";
      });
    }
  }

  // Function to remove admin from Firestore
  Future<void> _removeAdmin(String email) async {
    try {
      await FirebaseFirestore.instance
          .collection('groupChats')
          .doc(widget.chatId)
          .update({
            'admins': FieldValue.arrayRemove([email]),
          });
    } catch (e) {
      setState(() {
        errorMessage = "Failed to remove admin: ${e.toString()}";
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
    final cardColor = isDarkMode ? Colors.grey[800] : Colors.white;
    final errorColor = isDarkMode ? Colors.red[400] : Colors.red[600];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Group Participants"),
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
                  margin: const EdgeInsets.all(16),
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
                padding: const EdgeInsets.all(16),
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: participants.length,
                  separatorBuilder:
                      (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return FutureBuilder<DocumentSnapshot>(
                      future:
                          FirebaseFirestore.instance
                              .collection('users')
                              .doc(participants[index])
                              .get(),
                      builder: (context, snapshot) {
                        // Loading state
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Container(
                            padding: const EdgeInsets.all(16),
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
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 120,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.onSurface
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      width: 80,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.onSurface
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }

                        // Error state
                        if (!snapshot.hasData || !snapshot.data!.exists) {
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: theme.colorScheme.error,
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  "User not found",
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          );
                        }

                        // Success state
                        var userData = snapshot.data!;
                        var profilePhotoUrl = userData['profilePic'] ?? '';
                        final isCurrentUser =
                            participants[index] == currentUserEmail;
                        final username =
                            userData['username'] ?? participants[index];

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
                              vertical: 12,
                            ),
                            leading: CircleAvatar(
                              radius: 24,
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
                              username,
                              style: theme.textTheme.bodyLarge?.copyWith(
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
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        "You",
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                              color: theme.colorScheme.primary,
                                              fontWeight: FontWeight.w600,
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
