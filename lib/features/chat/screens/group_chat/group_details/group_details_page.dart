import 'package:chat_app/features/chat/screens/chat_list/chat_list_screen.dart';
import 'package:chat_app/features/chat/screens/group_chat/group_details/widgets/add_participants_sheet.dart';
import 'package:chat_app/features/chat/screens/group_chat/group_details/widgets/group_details_app_bar.dart';
import 'package:chat_app/features/chat/screens/group_chat/group_details/widgets/group_info_header.dart';
import 'package:chat_app/features/chat/screens/group_chat/group_details/widgets/participant_list_item.dart';
import 'package:chat_app/features/chat/screens/group_chat/group_details/widgets/participant_options_sheet.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GroupDetailsPage extends StatefulWidget {
  final String groupName;
  final String? groupPhotoUrl;
  final String chatId;

  const GroupDetailsPage({
    super.key,
    required this.groupName,
    this.groupPhotoUrl,
    required this.chatId,
  });

  @override
  _GroupDetailsPageState createState() => _GroupDetailsPageState();
}

class _GroupDetailsPageState extends State<GroupDetailsPage> {
  String? currentUserEmail;
  bool settingOnlyAdmin = false;
  bool currentUserIsAdmin = false;

  @override
  void initState() {
    super.initState();
    fetchCurrentUserEmail();
  }

  Future<void> fetchCurrentUserEmail() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      currentUserEmail = prefs.getString('userEmail');
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
      (targetUserBlocklist.data()?['contactEmails'] as List?)?.contains(currentUserEmail) == true) {
    return true;
  }

  // Check if target user is in current user's blocklist
  final currentUserBlocklist = await FirebaseFirestore.instance
      .collection('users')
      .doc(currentUserEmail)
      .collection('contacts')
      .doc('blockList')
      .get();

  if (currentUserBlocklist.exists && 
      (currentUserBlocklist.data()?['contactEmails'] as List?)?.contains(email) == true) {
    return true;
  }

  return false;
}

  Future<bool> checkIfCurrentUserIsAdmin(String currentUserEmail) async {
    try {
      DocumentSnapshot groupDoc =
          await FirebaseFirestore.instance
              .collection('groupChats')
              .doc(widget.chatId)
              .get();

      if (groupDoc.exists) {
        List<dynamic> admins = groupDoc['admins'];
        return admins.contains(currentUserEmail);
      }
      return false;
    } catch (e) {
      print("Error checking admin status: $e");
      return false;
    }
  }

  void showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _addParticipantsToThisGroups() async {
    try {
      DocumentSnapshot groupDoc =
          await FirebaseFirestore.instance
              .collection('groupChats')
              .doc(widget.chatId)
              .get();

      if (!groupDoc.exists) {
        showSnackbar("Group does not exist.");
        return;
      }

      String addMembersBy = groupDoc['AddMembersBy'] ?? 'anyone';
      List<String> admins =
          (groupDoc['admins'] as List<dynamic>?)?.cast<String>() ?? [];
      List<String> participants =
          (groupDoc['participants'] as List<dynamic>?)?.cast<String>() ?? [];

      if (addMembersBy == 'admin only' && !admins.contains(currentUserEmail)) {
        showSnackbar("You cannot add members, admin only.");
        return;
      }

      DocumentSnapshot contactsDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUserEmail)
              .collection('contacts')
              .doc('savedContacts')
              .get();

      if (!contactsDoc.exists ||
          contactsDoc['contactEmails'] == null ||
          (contactsDoc['contactEmails'] as List<dynamic>).isEmpty) {
        showSnackbar("You haven't any contacts to add in the group.");
        return;
      }

      List<String> contactEmails =
          (contactsDoc['contactEmails'] as List<dynamic>).cast<String>();

      QuerySnapshot userQuery =
          await FirebaseFirestore.instance
              .collection('users')
              .where(FieldPath.documentId, whereIn: contactEmails)
              .get();

      List<Map<String, dynamic>> userList =
          userQuery.docs.map((doc) {
            return {
              'email': doc.id,
              'username': doc['username'] ?? 'Unknown User',
              'profilePic': doc['profilePic'] ?? '',
              'isSelected': participants.contains(doc.id),
            };
          }).toList();

      // Then use it like this:
      List<Map<String, dynamic>> processedList = await Future.wait(
        userList.map((user) async {
          final isBlocked = await _isBlocked(user['email']);
          return {...user, 'isBlocked': isBlocked};
        }).toList(),
      );

      // showModalBottomSheet<bool>(
      //   context: context,
      //   isScrollControlled: true,
      //   builder: (BuildContext context) {
      //     return AddParticipantsSheet(
      //       userList: userList,
      //       onSave: (selectedEmails, deselectedEmails) async {

      bool isUpdated =
          await showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            builder: (BuildContext context) {
              return AddParticipantsSheet(
                userList: processedList,
                onSave: (selectedEmails, deselectedEmails) async {
                  await FirebaseFirestore.instance
                      .collection('groupChats')
                      .doc(widget.chatId)
                      .update({
                        'participants': FieldValue.arrayUnion(selectedEmails),
                      });

                  await FirebaseFirestore.instance
                      .collection('groupChats')
                      .doc(widget.chatId)
                      .update({
                        'participants': FieldValue.arrayRemove(
                          deselectedEmails,
                        ),
                        'admins': FieldValue.arrayRemove(deselectedEmails),
                      });

                  showSnackbar("Participants updated successfully.");
                },
              );
            },
          ) ??
          false;

      if (isUpdated) {
        setState(() {});
      }
    } catch (e) {
      showSnackbar("Error: $e");
    }
  }

  void showProfilePicture(String? photoUrl, String userName) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                photoUrl != null && photoUrl.isNotEmpty
                    ? Image.network(photoUrl)
                    : const Icon(Icons.person, size: 100),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(userName, style: const TextStyle(fontSize: 20)),
                ),
              ],
            ),
          ),
    );
  }

  Future<void> deleteCurrentUser(String email) async {
    bool? confirmation = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Confirm Deletion"),
            content: Text(
              "Are you sure you want to delete $email from the group?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Delete"),
              ),
            ],
          ),
    );

    if (confirmation == true) {
      try {
        var groupDoc = FirebaseFirestore.instance
            .collection('groupChats')
            .doc(widget.chatId);

        DocumentSnapshot groupData = await groupDoc.get();

        if (!groupData.exists) {
          showSnackbar("Group document does not exist.");
          return;
        }

        List<dynamic> admins = List<dynamic>.from(groupData['admins'] ?? []);
        List<dynamic> participants = List<dynamic>.from(
          groupData['participants'] ?? [],
        );

        bool adminRemoved = admins.remove(email);
        bool participantRemoved = participants.remove(email);

        if (!adminRemoved && !participantRemoved) {
          showSnackbar("Email not found in admins or participants.");
          return;
        }

        await groupDoc.update({'admins': admins, 'participants': participants});
        showSnackbar("User removed successfully.");

        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const ChatListScreen()),
        );
      } catch (e) {
        showSnackbar("Error removing user: $e");
      }
    }
  }

  Future<void> deleteUser(String email) async {
    bool? confirmation = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Confirm Deletion"),
            content: Text(
              "Are you sure you want to delete $email from the group?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Delete"),
              ),
            ],
          ),
    );

    if (confirmation == true) {
      var groupDoc = FirebaseFirestore.instance
          .collection('groupChats')
          .doc(widget.chatId);
      DocumentSnapshot groupData = await groupDoc.get();

      List<String> admins = List<String>.from(groupData['admins'] ?? []);
      List<String> participants = List<String>.from(
        groupData['participants'] ?? [],
      );

      if (admins.contains(email)) admins.remove(email);
      if (participants.contains(email)) participants.remove(email);

      await groupDoc.update({'admins': admins, 'participants': participants});
      setState(() {});
    }
  }

  Future<void> makeAdmin(String email) async {
    bool? confirmation = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Make Admin"),
            content: Text("Are you sure you want to make $email an admin?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Confirm"),
              ),
            ],
          ),
    );

    if (confirmation == true) {
      var groupDoc = FirebaseFirestore.instance
          .collection('groupChats')
          .doc(widget.chatId);
      DocumentSnapshot groupData = await groupDoc.get();

      List<String> admins = List<String>.from(groupData['admins'] ?? []);

      if (!admins.contains(email)) {
        admins.add(email);
        await groupDoc.update({'admins': admins});
        setState(() {});
      } else {
        showSnackbar("$email is already an admin.");
      }
    }
  }

  Future<void> removeAdmin(String email) async {
    bool? confirmation = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Remove Admin"),
            content: Text("Are you sure you want to remove $email as admin?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Confirm"),
              ),
            ],
          ),
    );

    if (confirmation == true) {
      var groupDoc = FirebaseFirestore.instance
          .collection('groupChats')
          .doc(widget.chatId);
      DocumentSnapshot groupData = await groupDoc.get();

      List<String> admins = List<String>.from(groupData['admins'] ?? []);

      if (admins.contains(email)) {
        admins.remove(email);
        await groupDoc.update({'admins': admins});
        setState(() {});
      } else {
        showSnackbar("$email is not an admin.");
      }
    }
  }

  Future<void> createChatWithUser(String email) async {
    String chatId = await createChat(currentUserEmail!, email);
    if (chatId.isNotEmpty) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const ChatListScreen()),
      );
    } else {
      showSnackbar("Failed to create chat");
    }
  }

  Future<String> createChat(String email1, String email2) async {
    try {
      var chatSnapshot =
          await FirebaseFirestore.instance
              .collection('chats')
              .where('participants', arrayContains: email1)
              .get();

      QueryDocumentSnapshot<Map<String, dynamic>>? existingChatDoc;
      for (var doc in chatSnapshot.docs) {
        var participants = doc['participants'] as List<dynamic>;
        if (participants.contains(email2) && participants.length == 2) {
          existingChatDoc = doc;
          break;
        }
      }

      if (existingChatDoc == null) {
        DocumentReference chatRef = await FirebaseFirestore.instance
            .collection('chats')
            .add({
              'participants': [email1, email2],
              'lastMessage': '',
              'chatType': 'individual',
              'timestamp': FieldValue.serverTimestamp(),
              'deletedBy': [],
            });
        return chatRef.id;
      } else {
        List<dynamic> deletedBy = existingChatDoc['deletedBy'] ?? [];
        if (deletedBy.contains(currentUserEmail!)) {
          await FirebaseFirestore.instance
              .collection('chats')
              .doc(existingChatDoc.id)
              .update({
                'deletedBy': FieldValue.arrayRemove([currentUserEmail!]),
              });
        }
        return existingChatDoc.id;
      }
    } catch (e) {
      showSnackbar("Error creating chat: $e");
      return "";
    }
  }

  void showOptionsBottomSheet(
    BuildContext context,
    String email,
    bool isAdmin,
    bool isCurrentUser,
    bool isCurrentUserAdmin,
  ) {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => ParticipantOptionsSheet(
            email: email,
            isAdmin: isAdmin,
            isCurrentUser: isCurrentUser,
            isCurrentUserAdmin: isCurrentUserAdmin,
            onMessagePressed: () {
              Navigator.pop(context);
              createChatWithUser(email);
            },
            onRemoveAdminPressed: () {
              Navigator.pop(context);
              removeAdmin(email);
            },
            onMakeAdminPressed: () {
              Navigator.pop(context);
              makeAdmin(email);
            },
            onDeletePressed: () {
              Navigator.pop(context);
              deleteUser(email);
            },
            onRemoveSelfPressed: () {
              Navigator.pop(context);
              deleteCurrentUser(currentUserEmail!);
            },
          ),
    );
  }

  void _viewImage(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Image.network(widget.groupPhotoUrl!),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final cardColor = isDarkMode ? Colors.grey[800] : Colors.grey[50];

    return Scaffold(
      appBar: const GroupDetailsAppBar(),
      body:
          currentUserEmail == null
              ? const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2.0,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              )
              : FutureBuilder<DocumentSnapshot>(
                future:
                    FirebaseFirestore.instance
                        .collection('groupChats')
                        .doc(widget.chatId)
                        .get(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.primary,
                        ),
                      ),
                    );
                  }

                  var groupData = snapshot.data!;
                  List<String> admins = List<String>.from(
                    groupData['admins'] ?? [],
                  );
                  List<String> participants = List<String>.from(
                    groupData['participants'] ?? [],
                  );

                  Set<String> allUsers = {
                    currentUserEmail!,
                    ...admins,
                    ...participants,
                  };

                  return FutureBuilder<QuerySnapshot>(
                    future:
                        FirebaseFirestore.instance
                            .collection('users')
                            .where(
                              FieldPath.documentId,
                              whereIn: allUsers.toList(),
                            )
                            .get(),
                    builder: (context, userSnapshot) {
                      if (!userSnapshot.hasData) {
                        return Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2.0,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              theme.colorScheme.primary,
                            ),
                          ),
                        );
                      }

                      Map<String, dynamic> userMap = {
                        for (var doc in userSnapshot.data!.docs)
                          doc.id: doc.data(),
                      };

                      List<String> sortedParticipants = [
                        currentUserEmail!,
                        ...admins.where((email) => email != currentUserEmail),
                        ...participants.where(
                          (email) =>
                              email != currentUserEmail &&
                              !admins.contains(email),
                        ),
                      ];

                      return CustomScrollView(
                        slivers: [
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: GroupInfoHeader(
                                groupName: widget.groupName,
                                groupPhotoUrl: widget.groupPhotoUrl,
                                onPhotoTap: () {
                                  if (widget.groupPhotoUrl != null &&
                                      widget.groupPhotoUrl!.isNotEmpty) {
                                    _viewImage(context);
                                  }
                                },
                              ),
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            sliver: SliverToBoxAdapter(
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Participants",
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  IconButton(
                                    icon: Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary
                                            .withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.add,
                                        color: theme.colorScheme.primary,
                                        size: 20,
                                      ),
                                    ),
                                    onPressed: _addParticipantsToThisGroups,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate((
                                context,
                                index,
                              ) {
                                String email = sortedParticipants[index];
                                var userData = userMap[email] ?? {};

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: cardColor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ParticipantListItem(
                                    userName:
                                        userData['username'] ?? 'Unknown User',
                                    email: email,
                                    userPhotoUrl: userData['profilePic'] ?? '',
                                    isAdmin: admins.contains(email),
                                    isCurrentUser: email == currentUserEmail,
                                    onTap:
                                        () => showProfilePicture(
                                          userData['profilePic'],
                                          userData['username'] ??
                                              'Unknown User',
                                        ),
                                    onLongPress: () async {
                                      currentUserIsAdmin =
                                          await checkIfCurrentUserIsAdmin(
                                            currentUserEmail!,
                                          );
                                      // Before showing the sheet, check for blocked users
                                      showOptionsBottomSheet(
                                        context,
                                        email,
                                        admins.contains(email),
                                        email == currentUserEmail,
                                        currentUserIsAdmin,
                                      );
                                    },
                                  ),
                                );
                              }, childCount: sortedParticipants.length),
                            ),
                          ),
                          const SliverPadding(
                            padding: EdgeInsets.only(bottom: 16),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
    );
  }
}
