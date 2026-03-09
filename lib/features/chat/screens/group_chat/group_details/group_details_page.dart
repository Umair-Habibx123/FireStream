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
  bool currentUserIsAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserEmail();
  }

  Future<void> _loadCurrentUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => currentUserEmail = prefs.getString('userEmail'));
  }

  Future<bool> _isBlocked(String email) async {
    final targetDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(email)
        .collection('contacts')
        .doc('blockList')
        .get();
    if (targetDoc.exists &&
        (targetDoc.data()?['contactEmails'] as List?)
                ?.contains(currentUserEmail) ==
            true) return true;

    final myDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserEmail)
        .collection('contacts')
        .doc('blockList')
        .get();
    if (myDoc.exists &&
        (myDoc.data()?['contactEmails'] as List?)?.contains(email) == true)
      return true;

    return false;
  }

  Future<bool> _checkIfAdmin(String email) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('groupChats')
          .doc(widget.chatId)
          .get();
      return (doc['admins'] as List).contains(email);
    } catch (_) {
      return false;
    }
  }

  void _snackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            isError ? Colors.red.shade600 : const Color(0xFF1565C0),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<bool?> _confirm(String title, String body,
      {String confirmLabel = 'Confirm', Color confirmColor = const Color(0xFFE53935)}) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: TextStyle(color: Colors.grey.shade600)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmLabel,
                style: TextStyle(
                    color: confirmColor, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Future<void> _addParticipants() async {
    try {
      final groupDoc = await FirebaseFirestore.instance
          .collection('groupChats')
          .doc(widget.chatId)
          .get();

      if (!groupDoc.exists) {
        _snackBar('Group does not exist.', isError: true);
        return;
      }

      final addMembersBy = groupDoc['AddMembersBy'] ?? 'anyone';
      final admins = List<String>.from(groupDoc['admins'] ?? []);
      final participants = List<String>.from(groupDoc['participants'] ?? []);

      if (addMembersBy == 'admin only' &&
          !admins.contains(currentUserEmail)) {
        _snackBar('Only admins can add members.', isError: true);
        return;
      }

      final contactsDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserEmail)
          .collection('contacts')
          .doc('savedContacts')
          .get();

      final contactEmails = List<String>.from(
          contactsDoc.data()?['contactEmails'] ?? []);

      if (contactEmails.isEmpty) {
        _snackBar('You have no saved contacts to add.', isError: true);
        return;
      }

      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where(FieldPath.documentId, whereIn: contactEmails)
          .get();

      final userList = userQuery.docs.map((doc) => {
            'email': doc.id,
            'username': doc['username'] ?? 'Unknown',
            'profilePic': doc['profilePic'] ?? '',
            'isSelected': participants.contains(doc.id),
          }).toList();

      final processed = await Future.wait(
        userList.map((u) async => {
              ...u,
              'isBlocked': await _isBlocked(u['email'] as String),
            }),
      );

      if (!mounted) return;

      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => AddParticipantsSheet(
          userList: processed,
          onSave: (selected, deselected) async {
            await FirebaseFirestore.instance
                .collection('groupChats')
                .doc(widget.chatId)
                .update({
              'participants': FieldValue.arrayUnion(selected),
            });
            await FirebaseFirestore.instance
                .collection('groupChats')
                .doc(widget.chatId)
                .update({
              'participants': FieldValue.arrayRemove(deselected),
              'admins': FieldValue.arrayRemove(deselected),
            });
            _snackBar('Participants updated');
            setState(() {});
          },
        ),
      );
    } catch (e) {
      _snackBar('Error: $e', isError: true);
    }
  }

  Future<void> _deleteUser(String email) async {
    final confirmed = await _confirm(
      'Remove Participant',
      'Remove $email from the group?',
      confirmLabel: 'Remove',
    );
    if (confirmed != true) return;

    final ref = FirebaseFirestore.instance
        .collection('groupChats')
        .doc(widget.chatId);
    final doc = await ref.get();
    final admins = List<String>.from(doc['admins'] ?? []);
    final participants = List<String>.from(doc['participants'] ?? []);
    admins.remove(email);
    participants.remove(email);
    await ref.update({'admins': admins, 'participants': participants});
    _snackBar('User removed');
    setState(() {});
  }

  Future<void> _deleteCurrentUser(String email) async {
    final confirmed = await _confirm(
      'Leave Group',
      'Are you sure you want to leave this group?',
      confirmLabel: 'Leave',
    );
    if (confirmed != true) return;

    final ref = FirebaseFirestore.instance
        .collection('groupChats')
        .doc(widget.chatId);
    final doc = await ref.get();
    final admins = List<String>.from(doc['admins'] ?? []);
    final participants = List<String>.from(doc['participants'] ?? []);
    admins.remove(email);
    participants.remove(email);
    await ref.update({'admins': admins, 'participants': participants});

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ChatListScreen()),
    );
  }

  Future<void> _makeAdmin(String email) async {
    final confirmed = await _confirm(
      'Make Admin',
      'Grant admin privileges to $email?',
      confirmLabel: 'Make Admin',
      confirmColor: Colors.green.shade700,
    );
    if (confirmed != true) return;

    await FirebaseFirestore.instance
        .collection('groupChats')
        .doc(widget.chatId)
        .update({'admins': FieldValue.arrayUnion([email])});
    _snackBar('$email is now an admin');
    setState(() {});
  }

  Future<void> _removeAdmin(String email) async {
    final confirmed = await _confirm(
      'Remove Admin',
      'Revoke admin privileges from $email?',
      confirmLabel: 'Remove',
      confirmColor: Colors.orange.shade700,
    );
    if (confirmed != true) return;

    await FirebaseFirestore.instance
        .collection('groupChats')
        .doc(widget.chatId)
        .update({'admins': FieldValue.arrayRemove([email])});
    _snackBar('Admin privileges removed');
    setState(() {});
  }

  Future<void> _createChatWithUser(String email) async {
    try {
      final chatSnapshot = await FirebaseFirestore.instance
          .collection('chats')
          .where('participants', arrayContains: currentUserEmail)
          .get();

      String chatId = '';
      for (var doc in chatSnapshot.docs) {
        final participants = doc['participants'] as List;
        if (participants.contains(email) && participants.length == 2) {
          chatId = doc.id;
          final deletedBy = doc['deletedBy'] as List? ?? [];
          if (deletedBy.contains(currentUserEmail)) {
            await FirebaseFirestore.instance
                .collection('chats')
                .doc(doc.id)
                .update({'deletedBy': FieldValue.arrayRemove([currentUserEmail])});
          }
          break;
        }
      }

      if (chatId.isEmpty) {
        final ref = await FirebaseFirestore.instance.collection('chats').add({
          'participants': [currentUserEmail, email],
          'lastMessage': '',
          'chatType': 'individual',
          'timestamp': FieldValue.serverTimestamp(),
          'deletedBy': [],
        });
        chatId = ref.id;
      }

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ChatListScreen()),
      );
    } catch (e) {
      _snackBar('Failed to open chat: $e', isError: true);
    }
  }

  void _showOptionsSheet(BuildContext context, String email, bool isAdmin,
      bool isCurrentUser, bool isCurrentUserAdmin) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => ParticipantOptionsSheet(
        email: email,
        isAdmin: isAdmin,
        isCurrentUser: isCurrentUser,
        isCurrentUserAdmin: isCurrentUserAdmin,
        onMessagePressed: () {
          Navigator.pop(context);
          _createChatWithUser(email);
        },
        onRemoveAdminPressed: () {
          Navigator.pop(context);
          _removeAdmin(email);
        },
        onMakeAdminPressed: () {
          Navigator.pop(context);
          _makeAdmin(email);
        },
        onDeletePressed: () {
          Navigator.pop(context);
          _deleteUser(email);
        },
        onRemoveSelfPressed: () {
          Navigator.pop(context);
          _deleteCurrentUser(currentUserEmail!);
        },
      ),
    );
  }

  void _viewPhoto(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.network(widget.groupPhotoUrl!),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (currentUserEmail == null) {
      return const Scaffold(
        body: Center(
            child: CircularProgressIndicator(
                color: Color(0xFF1565C0), strokeWidth: 2.5)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: const GroupDetailsAppBar(),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('groupChats')
            .doc(widget.chatId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(
                  color: Color(0xFF1565C0), strokeWidth: 2.5),
            );
          }

          final groupData = snapshot.data!;
          final admins = List<String>.from(groupData['admins'] ?? []);
          final participants =
              List<String>.from(groupData['participants'] ?? []);
          final isCurrentUserAdmin = admins.contains(currentUserEmail);

          final sortedParticipants = [
            if (participants.contains(currentUserEmail)) currentUserEmail!,
            ...admins.where((e) => e != currentUserEmail),
            ...participants.where(
                (e) => e != currentUserEmail && !admins.contains(e)),
          ];

          return FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .where(FieldPath.documentId,
                    whereIn: sortedParticipants.isEmpty
                        ? ['_']
                        : sortedParticipants)
                .get(),
            builder: (context, userSnap) {
              final userMap = userSnap.hasData
                  ? {
                      for (var doc in userSnap.data!.docs)
                        doc.id: doc.data() as Map<String, dynamic>
                    }
                  : <String, Map<String, dynamic>>{};

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Group header banner
                  SliverToBoxAdapter(
                    child: GroupInfoHeader(
                      groupName: widget.groupName,
                      groupPhotoUrl: widget.groupPhotoUrl,
                      onPhotoTap: () {
                        if (widget.groupPhotoUrl?.isNotEmpty == true) {
                          _viewPhoto(context);
                        }
                      },
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 20)),

                  // Section header
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverToBoxAdapter(
                      child: Row(
                        children: [
                          const Text(
                            'Participants',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1565C0).withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${sortedParticipants.length}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF1565C0),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: _addParticipants,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1565C0),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.person_add_rounded,
                                      size: 14, color: Colors.white),
                                  SizedBox(width: 5),
                                  Text(
                                    'Add',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 10)),

                  // Participants list
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final email = sortedParticipants[index];
                          final userData = userMap[email] ?? {};
                          final isAdmin = admins.contains(email);
                          final isCurrentUser = email == currentUserEmail;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ParticipantListItem(
                              userName: userData['username'] ?? 'Unknown',
                              email: email,
                              userPhotoUrl: userData['profilePic'] ?? '',
                              isAdmin: isAdmin,
                              isCurrentUser: isCurrentUser,
                              onTap: () {
                                // View profile photo
                                final photoUrl =
                                    userData['profilePic'] as String? ?? '';
                                if (photoUrl.isNotEmpty) {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => Dialog(
                                      backgroundColor: Colors.transparent,
                                      child: ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(16),
                                        child: Image.network(photoUrl),
                                      ),
                                    ),
                                  );
                                }
                              },
                              onLongPress: () async {
                                final adminStatus =
                                    await _checkIfAdmin(currentUserEmail!);
                                if (!mounted) return;
                                _showOptionsSheet(
                                  context,
                                  email,
                                  isAdmin,
                                  isCurrentUser,
                                  adminStatus,
                                );
                              },
                            ),
                          );
                        },
                        childCount: sortedParticipants.length,
                      ),
                    ),
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