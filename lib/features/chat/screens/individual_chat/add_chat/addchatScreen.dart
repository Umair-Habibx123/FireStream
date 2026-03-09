import 'package:chat_app/features/chat/screens/chat_list/chat_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:validators/validators.dart';

class AddNewChatScreen extends StatefulWidget {
  const AddNewChatScreen({super.key});

  @override
  _AddNewChatScreenState createState() => _AddNewChatScreenState();
}

class _AddNewChatScreenState extends State<AddNewChatScreen> {
  final TextEditingController _emailController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _searchResult = "";
  String _currentUserEmail = "";
  List<Map<String, dynamic>> _contacts = [];
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoadingContacts = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserEmail();
    _emailController.addListener(_searchUser);
  }

  @override
  void dispose() {
    _emailController.removeListener(_searchUser);
    _emailController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUserEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUserEmail = prefs.getString('userEmail') ?? '';
    });
    await _loadContacts();
  }

  void _showSnackbar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? const Color(0xFFE53935) : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _loadContacts() async {
    setState(() => _isLoadingContacts = true);

    try {
      final results = await Future.wait([
        FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUserEmail)
            .collection('contacts')
            .doc('savedContacts')
            .get(),
        FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUserEmail)
            .collection('contacts')
            .doc('blockList')
            .get(),
      ]);

      final savedContactsDoc = results[0];
      final blockListDoc = results[1];

      if (savedContactsDoc.exists) {
        List<dynamic> contactEmails =
            savedContactsDoc['contactEmails'] ?? [];
        List<dynamic> blockListEmails =
            blockListDoc.exists ? blockListDoc['contactEmails'] ?? [] : [];

        List<Map<String, dynamic>> contacts = [];

        for (String email in contactEmails) {
          if (blockListEmails.contains(email)) continue;

          DocumentSnapshot userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(email)
              .get();

          if (userDoc.exists) {
            contacts.add({
              'email': email,
              'username': userDoc['username'],
              'profilePic': userDoc['profilePic'],
            });
          }
        }

        setState(() => _contacts = contacts);
      }
    } catch (e) {
      _showSnackbar("Error loading contacts: $e");
    } finally {
      setState(() => _isLoadingContacts = false);
    }
  }

  void _searchUser() async {
    String email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() {
        _searchResults = [];
        _searchResult = "";
      });
      return;
    }

    if (!isEmail(email)) {
      setState(() => _searchResult = "Enter a valid email address");
      return;
    }

    if (email == _currentUserEmail) {
      setState(() => _searchResult = "You cannot chat with yourself");
      return;
    }

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(email)
          .get();

      if (userDoc.exists) {
        final blockChecks = await Future.wait([
          FirebaseFirestore.instance
              .collection('users')
              .doc(email)
              .collection('contacts')
              .doc('blockList')
              .get(),
          FirebaseFirestore.instance
              .collection('users')
              .doc(_currentUserEmail)
              .collection('contacts')
              .doc('blockList')
              .get(),
        ]);

        List<dynamic> searchedUserBlocklist =
            blockChecks[0].exists ? blockChecks[0]['contactEmails'] ?? [] : [];
        List<dynamic> currentUserBlocklist =
            blockChecks[1].exists ? blockChecks[1]['contactEmails'] ?? [] : [];

        if (searchedUserBlocklist.contains(_currentUserEmail)) {
          setState(() {
            _searchResult = "This user has blocked you";
            _searchResults = [];
          });
          return;
        }

        if (currentUserBlocklist.contains(email)) {
          setState(() {
            _searchResult = "You have blocked this user";
            _searchResults = [];
          });
          return;
        }

        setState(() {
          _searchResults = [
            {
              'email': email,
              'username': userDoc['username'],
              'profilePic': userDoc['profilePic'],
            },
          ];
          _searchResult = "";
        });
      } else {
        setState(() {
          _searchResult = "No user found with this email";
          _searchResults = [];
        });
      }
    } catch (e) {
      _showSnackbar("Error searching: $e");
    }
  }

  void _createChatWithUser(String email) async {
    final blockChecks = await Future.wait([
      FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUserEmail)
          .collection('contacts')
          .doc('blockList')
          .get(),
      FirebaseFirestore.instance
          .collection('users')
          .doc(email)
          .collection('contacts')
          .doc('blockList')
          .get(),
    ]);

    final currentUserBlocklist =
        blockChecks[0].exists ? blockChecks[0]['contactEmails'] ?? [] : [];
    final otherUserBlocklist =
        blockChecks[1].exists ? blockChecks[1]['contactEmails'] ?? [] : [];

    if (currentUserBlocklist.contains(email)) {
      _showSnackbar("You have blocked this user");
      return;
    }

    if (otherUserBlocklist.contains(_currentUserEmail)) {
      _showSnackbar("This user has blocked you");
      return;
    }

    String chatId = await createChat(_currentUserEmail, email);
    if (chatId.isNotEmpty) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ChatListScreen()),
        );
      }
    } else {
      _showSnackbar("Failed to create chat");
    }
  }

  Future<String> createChat(String email1, String email2) async {
    try {
      var chatSnapshot = await FirebaseFirestore.instance
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
        DocumentReference chatRef =
            await FirebaseFirestore.instance.collection('chats').add({
          'participants': [email1, email2],
          'lastMessage': '',
          'chatType': 'individual',
          'timestamp': FieldValue.serverTimestamp(),
          'deletedBy': [],
        });
        return chatRef.id;
      } else {
        List<dynamic> deletedBy = existingChatDoc['deletedBy'] ?? [];
        if (deletedBy.contains(_currentUserEmail)) {
          await FirebaseFirestore.instance
              .collection('chats')
              .doc(existingChatDoc.id)
              .update({
            'deletedBy': FieldValue.arrayRemove([_currentUserEmail]),
          });
        }
        return existingChatDoc.id;
      }
    } catch (e) {
      _showSnackbar("Error creating chat: $e");
      return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    final listToShow =
        _emailController.text.isEmpty ? _contacts : _searchResults;
    final isShowingContacts = _emailController.text.isEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [const Color(0xFF1565C0), Colors.blue.shade700],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.shade900.withOpacity(0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'New Conversation',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
            letterSpacing: 0.2,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                TextField(
                  controller: _emailController,
                  focusNode: _focusNode,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(
                      fontSize: 15, color: Color(0xFF1A1A2E)),
                  decoration: InputDecoration(
                    hintText: 'Search by email address...',
                    hintStyle: TextStyle(
                        color: Colors.grey.shade400, fontSize: 15),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 16),
                    prefixIcon: Icon(Icons.search_rounded,
                        color: const Color(0xFF1565C0), size: 22),
                    suffixIcon: _emailController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.close_rounded,
                                color: Colors.grey.shade400, size: 20),
                            onPressed: () {
                              _emailController.clear();
                              _focusNode.unfocus();
                            },
                          )
                        : null,
                  ),
                ),
                if (_searchResult.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            size: 14, color: Colors.red.shade400),
                        const SizedBox(width: 6),
                        Text(
                          _searchResult,
                          style: TextStyle(
                            color: Colors.red.shade400,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Section label
          if (isShowingContacts && _contacts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: Row(
                children: [
                  Text(
                    'CONTACTS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade400,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 1,
                      color: Colors.grey.shade200,
                    ),
                  ),
                ],
              ),
            ),

          // Content
          Expanded(
            child: _isLoadingContacts
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF1565C0),
                      strokeWidth: 2.5,
                    ),
                  )
                : listToShow.isEmpty
                    ? _buildEmptyState(isShowingContacts)
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: listToShow.length,
                        itemBuilder: (context, index) {
                          final user = listToShow[index];
                          return _buildContactTile(user);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactTile(Map<String, dynamic> user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _createChatWithUser(user['email']),
          splashColor: const Color(0xFF1565C0).withOpacity(0.08),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.blue.shade100, width: 1.5),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: user['profilePic'] != null &&
                            user['profilePic'].toString().isNotEmpty
                        ? Image.network(
                            user['profilePic'],
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _defaultAvatar(),
                          )
                        : _defaultAvatar(),
                  ),
                ),
                const SizedBox(width: 14),

                // Name + email
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user['username'] ?? 'Unknown',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        user['email'],
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1565C0).withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 18,
                    color: Color(0xFF1565C0),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isContacts) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isContacts
                  ? Icons.people_outline_rounded
                  : Icons.search_off_rounded,
              size: 38,
              color: const Color(0xFF1565C0).withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isContacts ? 'No contacts yet' : 'No results found',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isContacts
                ? 'Search for someone by email to start chatting'
                : 'Try a different email address',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _defaultAvatar() {
    return Container(
      color: Colors.blue.shade50,
      child: Icon(Icons.person_rounded,
          size: 26, color: Colors.blue.shade300),
    );
  }
}