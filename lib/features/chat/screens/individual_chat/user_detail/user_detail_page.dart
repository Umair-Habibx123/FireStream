import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chat_app/features/chat/screens/chat_list/chat_list_screen.dart';
import 'widgets/user_info_card.dart';
import 'widgets/action_buttons.dart';
import 'widgets/group_selection_dialog.dart';

class UserDetailPage extends StatefulWidget {
  final String email;
  final String currentUserEmail;

  const UserDetailPage({
    super.key,
    required this.email,
    required this.currentUserEmail,
  });

  @override
  _UserDetailPageState createState() => _UserDetailPageState();
}

class _UserDetailPageState extends State<UserDetailPage> {
  late String email;
  late String currentUserEmail;

  @override
  void initState() {
    super.initState();
    email = widget.email;
    currentUserEmail = widget.currentUserEmail;
  }

  Future<Map<String, dynamic>?> _fetchUserDetails() async {
    var userDoc =
        await FirebaseFirestore.instance.collection('users').doc(email).get();
    return userDoc.exists ? userDoc.data() : null;
  }

  Future<bool> _isContactSaved(String email) async {
    try {
      DocumentSnapshot savedContactsDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUserEmail)
              .collection('contacts')
              .doc('savedContacts')
              .get();

      if (savedContactsDoc.exists) {
        List<dynamic> contactEmails = savedContactsDoc['contactEmails'] ?? [];
        return contactEmails.contains(email);
      }
      return false;
    } catch (e) {
      debugPrint("Error checking saved contact: $e");
      return false;
    }
  }

  Future<void> _addToContacts(BuildContext context) async {
    try {
      setState(() {});

      DocumentReference userDocRef = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserEmail);

      var contactsDoc =
          await userDocRef.collection('contacts').doc('savedContacts').get();

      if (!contactsDoc.exists) {
        await userDocRef.collection('contacts').doc('savedContacts').set({
          'contactEmails': [],
        });
      }

      await userDocRef.collection('contacts').doc('savedContacts').update({
        'contactEmails': FieldValue.arrayUnion([email]),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User added to your contacts.")),
      );

      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to add contact: ${e.toString()}")),
      );
    }
  }

  Future<void> _addToBlockList(BuildContext context) async {
    try {
      setState(() {});

      DocumentReference userDocRef = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserEmail);

      var contactsDoc =
          await userDocRef.collection('contacts').doc('blockList').get();

      if (!contactsDoc.exists) {
        await userDocRef.collection('contacts').doc('blockList').set({
          'contactEmails': [],
        });
      }

      await userDocRef.collection('contacts').doc('blockList').update({
        'contactEmails': FieldValue.arrayUnion([email]),
      });

      var chatSnapshot =
          await FirebaseFirestore.instance
              .collection('chats')
              .where('participants', arrayContains: currentUserEmail)
              .get();

      for (var doc in chatSnapshot.docs) {
        var participants = List<String>.from(doc['participants']);
        if (participants.length == 2 && participants.contains(email)) {
          await FirebaseFirestore.instance
              .collection('chats')
              .doc(doc.id)
              .delete();
          break;
        }
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("User added to blacklist.")));

      setState(() {});

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const ChatListScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to adding in blacklist: ${e.toString()}"),
        ),
      );
    }
  }

  Future<List<QueryDocumentSnapshot>> _fetchEligibleGroups() async {
    var groupChats =
        await FirebaseFirestore.instance.collection('groupChats').get();
    return groupChats.docs.where((doc) {
      var addMembersBy = doc['AddMembersBy'];
      var participants = List<String>.from(doc['participants']);
      var admins = List<String>.from(doc['admins']);

      if (addMembersBy == "anyone") {
        return participants.contains(currentUserEmail);
      } else if (addMembersBy == "admin only") {
        return admins.contains(currentUserEmail) &&
            participants.contains(currentUserEmail);
      }
      return false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "User Profile",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.blueAccent,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: FutureBuilder<Map<String, dynamic>?>(
          future: _fetchUserDetails(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator.adaptive(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                ),
              );
            }
            if (!snapshot.hasData || snapshot.data == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_off_rounded,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "User not found",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }

            final userDetails = snapshot.data!;
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  UserInfoCard(
                    profileUrl: userDetails['profilePic'] ?? "",
                    username: userDetails['username'] ?? "Unknown User",
                    email: email,
                    onImageTap: (url) => _viewImage(context, url),
                  ),
                  const SizedBox(height: 24),
                  ActionButtons(
                    email: email,
                    currentUserEmail: currentUserEmail,
                    onAddToContacts: () => _addToContacts(context),
                    onAddToBlockList: () => _addToBlockList(context),
                    onAddToGroup: () => _showAddToGroupDialog(context),
                    isContactSavedFuture: _isContactSaved(email),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _viewImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Stack(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Center(
                  child: Hero(
                    tag: 'profile-image',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            width: 300,
                            height: 300,
                            color: Colors.black.withOpacity(0.7),
                            child: Center(
                              child: CircularProgressIndicator(
                                value:
                                    loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            (loadingProgress
                                                    .expectedTotalBytes ??
                                                1)
                                        : null,
                                color: Colors.white,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 300,
                            height: 300,
                            color: Colors.black.withOpacity(0.7),
                            child: const Center(
                              child: Icon(
                                Icons.person,
                                size: 80,
                                color: Colors.white,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 20,
                right: 20,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddToGroupDialog(BuildContext context) async {
    final eligibleGroups = await _fetchEligibleGroups();

    if (eligibleGroups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("No eligible groups available"),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          child: GroupSelectionDialog(
            eligibleGroups: eligibleGroups,
            email: email,
            currentUserEmail: currentUserEmail,
          ),
        );
      },
    );
  }
}
