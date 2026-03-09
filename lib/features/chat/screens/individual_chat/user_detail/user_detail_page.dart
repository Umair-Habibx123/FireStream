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
      DocumentSnapshot savedContactsDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserEmail)
          .collection('contacts')
          .doc('savedContacts')
          .get();

      if (savedContactsDoc.exists) {
        List<dynamic> contactEmails =
            savedContactsDoc['contactEmails'] ?? [];
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

      var contactsDoc = await userDocRef
          .collection('contacts')
          .doc('savedContacts')
          .get();

      if (!contactsDoc.exists) {
        await userDocRef
            .collection('contacts')
            .doc('savedContacts')
            .set({'contactEmails': []});
      }

      await userDocRef
          .collection('contacts')
          .doc('savedContacts')
          .update({
        'contactEmails': FieldValue.arrayUnion([email]),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Added to contacts"),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed: ${e.toString()}")),
        );
      }
    }
  }

  Future<void> _addToBlockList(BuildContext context) async {
    // Confirm dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Block User',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to block $email?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel',
                style: TextStyle(color: Colors.grey.shade600)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Block',
                style: TextStyle(
                    color: Color(0xFFE53935),
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      setState(() {});
      DocumentReference userDocRef = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserEmail);

      var contactsDoc =
          await userDocRef.collection('contacts').doc('blockList').get();

      if (!contactsDoc.exists) {
        await userDocRef
            .collection('contacts')
            .doc('blockList')
            .set({'contactEmails': []});
      }

      await userDocRef.collection('contacts').doc('blockList').update({
        'contactEmails': FieldValue.arrayUnion([email]),
      });

      var chatSnapshot = await FirebaseFirestore.instance
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

      setState(() {});

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ChatListScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed: ${e.toString()}")),
        );
      }
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
      backgroundColor: const Color(0xFFF7F8FC),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back_ios_rounded,
                color: Colors.white, size: 18),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.more_vert_rounded,
                  color: Colors.white, size: 18),
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _fetchUserDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF1565C0),
                strokeWidth: 2.5,
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off_rounded,
                      size: 56, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'User not found',
                    style: TextStyle(
                      fontSize: 17,
                      color: Colors.grey.shade500,
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
                // Header card (full-width gradient, extends behind appbar)
                UserInfoCard(
                  profileUrl: userDetails['profilePic'] ?? "",
                  username: userDetails['username'] ?? "Unknown User",
                  email: email,
                  onImageTap: (url) => _viewImage(context, url),
                ),

                // Action buttons
                Transform.translate(
                  offset: const Offset(0, -12),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: ActionButtons(
                        email: email,
                        currentUserEmail: currentUserEmail,
                        onAddToContacts: () => _addToContacts(context),
                        onAddToBlockList: () => _addToBlockList(context),
                        onAddToGroup: () => _showAddToGroupDialog(context),
                        isContactSavedFuture: _isContactSaved(email),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  void _viewImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
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
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Container(
                        width: 300,
                        height: 300,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.person,
                            size: 80, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded,
                      color: Colors.white, size: 20),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddToGroupDialog(BuildContext context) async {
    final eligibleGroups = await _fetchEligibleGroups();

    if (eligibleGroups.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("No eligible groups available"),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
      return;
    }

    if (mounted) {
      showDialog(
        context: context,
        builder: (_) => Dialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          child: GroupSelectionDialog(
            eligibleGroups: eligibleGroups,
            email: email,
            currentUserEmail: currentUserEmail,
          ),
        ),
      );
    }
  }
}