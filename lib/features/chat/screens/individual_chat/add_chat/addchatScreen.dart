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
  String _searchResult = "";
  String _currentUserEmail = "";
  List<Map<String, dynamic>> _contacts = [];
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoadingContacts = false; // Added loading state

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
    super.dispose();
  }

  Future<void> _loadCurrentUserEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUserEmail = prefs.getString('userEmail') ?? '';
    });
    await _loadContacts();
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

  Future<void> _loadContacts() async {
    setState(() {
      _isLoadingContacts = true;
    });

    try {
      DocumentSnapshot savedContactsDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(_currentUserEmail)
              .collection('contacts')
              .doc('savedContacts')
              .get();

      DocumentSnapshot blockListDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(_currentUserEmail)
              .collection('contacts')
              .doc('blockList')
              .get();

      if (savedContactsDoc.exists) {
        List<dynamic> contactEmails = savedContactsDoc['contactEmails'] ?? [];
        List<dynamic> blockListEmails =
            blockListDoc.exists ? blockListDoc['contactEmails'] ?? [] : [];

        List<Map<String, dynamic>> contacts = [];

        for (String email in contactEmails) {
          if (blockListEmails.contains(email)) continue;

          DocumentSnapshot userDoc =
              await FirebaseFirestore.instance
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

        setState(() {
          _contacts = contacts;
        });
      }
    } catch (e) {
      showSnackbar("Error loading contacts: $e");
    } finally {
      setState(() {
        _isLoadingContacts = false;
      });
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
      setState(() {
        _searchResult = "Invalid email format";
      });
      return;
    }

    if (email == _currentUserEmail) {
      setState(() {
        _searchResult = "You cannot chat with yourself";
      });
      return;
    }

    try {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(email).get();

      if (userDoc.exists) {
        // Check if current user is blocked by the searched user
        DocumentSnapshot searchedUserBlocklistDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(email)
                .collection('contacts')
                .doc('blockList')
                .get();

        List<dynamic> searchedUserBlocklist =
            searchedUserBlocklistDoc.exists
                ? searchedUserBlocklistDoc['contactEmails'] ?? []
                : [];

        if (searchedUserBlocklist.contains(_currentUserEmail)) {
          setState(() {
            _searchResult = "This user has blocked you";
            _searchResults = [];
          });
          return;
        }

        // Check if searched user is in current user's blocklist
        DocumentSnapshot currentUserBlocklistDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(_currentUserEmail)
                .collection('contacts')
                .doc('blockList')
                .get();

        List<dynamic> currentUserBlocklist =
            currentUserBlocklistDoc.exists
                ? currentUserBlocklistDoc['contactEmails'] ?? []
                : [];

        if (currentUserBlocklist.contains(email)) {
          setState(() {
            _searchResult = "You have blocked this user";
            _searchResults = [];
          });
          return;
        }

        // If neither has blocked the other, show the result
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
          _searchResult = "No user found with that email";
          _searchResults = [];
        });
      }
    } catch (e) {
      showSnackbar("Error searching user: $e");
    }
  }

  // void _createChatWithUser(String email) async {
  //   String chatId = await createChat(_currentUserEmail, email);
  //   if (chatId.isNotEmpty) {
  //     Navigator.of(context).pushReplacement(
  //       MaterialPageRoute(builder: (context) => const ChatListScreen()),
  //     );
  //   } else {
  //     showSnackbar("Failed to create chat");
  //   }
  // }

  void _createChatWithUser(String email) async {
    // Check mutual blocking before creating chat
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
      showSnackbar("You have blocked this user");
      return;
    }

    if (otherUserBlocklist.contains(_currentUserEmail)) {
      showSnackbar("This user has blocked you");
      return;
    }

    // Proceed with chat creation if no blocks exist
    String chatId = await createChat(_currentUserEmail, email);
    if (chatId.isNotEmpty) {
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
      showSnackbar("Error creating chat: $e");
      return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    final listToShow =
        _emailController.text.isEmpty ? _contacts : _searchResults;
    final isShowingContacts = _emailController.text.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "New Chat",
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
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Material(
                elevation: 0,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.shade100.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: "Search by email",
                            labelStyle: TextStyle(color: Colors.grey.shade600),
                            floatingLabelBehavior: FloatingLabelBehavior.never,
                            border: InputBorder.none,
                            prefixIcon: Icon(
                              Icons.search,
                              color: Colors.blue.shade400,
                            ),
                            suffixIcon:
                                _emailController.text.isNotEmpty
                                    ? IconButton(
                                      icon: Icon(
                                        Icons.close,
                                        color: Colors.grey.shade500,
                                      ),
                                      onPressed: () => _emailController.clear(),
                                    )
                                    : null,
                            filled: false,
                          ),
                          style: const TextStyle(fontSize: 16),
                        ),
                        if (_searchResult.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Text(
                              _searchResult,
                              style: TextStyle(
                                color: Colors.red.shade400,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Material(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.shade100.withOpacity(0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child:
                          _isLoadingContacts
                              ? const Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.blueAccent,
                                  ),
                                ),
                              )
                              : Column(
                                children: [
                                  if (isShowingContacts && _contacts.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        16,
                                        16,
                                        16,
                                        8,
                                      ),
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          'Your Contacts',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                      ),
                                    ),
                                  if (listToShow.isEmpty)
                                    Expanded(
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.people_outline,
                                              size: 64,
                                              color: Colors.blue.shade200,
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              "No contacts found",
                                              style: TextStyle(
                                                color: Colors.grey.shade600,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              isShowingContacts
                                                  ? "Your contacts will appear here"
                                                  : "Try searching with a different email",
                                              style: TextStyle(
                                                color: Colors.grey.shade500,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  else
                                    Expanded(
                                      child: ListView.builder(
                                        physics: const BouncingScrollPhysics(),
                                        itemCount: listToShow.length,
                                        itemBuilder: (context, index) {
                                          final user = listToShow[index];
                                          return Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              onTap:
                                                  () => _createChatWithUser(
                                                    user['email'],
                                                  ),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 16.0,
                                                      vertical: 12.0,
                                                    ),
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      width: 48,
                                                      height: 48,
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        border: Border.all(
                                                          color:
                                                              Colors
                                                                  .blue
                                                                  .shade100,
                                                          width: 1.5,
                                                        ),
                                                      ),
                                                      child: ClipRRect(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              24,
                                                            ),
                                                        child:
                                                            user['profilePic'] !=
                                                                    null
                                                                ? Image.network(
                                                                  user['profilePic'],
                                                                  fit:
                                                                      BoxFit
                                                                          .cover,
                                                                  errorBuilder:
                                                                      (
                                                                        context,
                                                                        error,
                                                                        stackTrace,
                                                                      ) => Icon(
                                                                        Icons
                                                                            .person,
                                                                        size:
                                                                            24,
                                                                        color:
                                                                            Colors.blue.shade300,
                                                                      ),
                                                                )
                                                                : Icon(
                                                                  Icons.person,
                                                                  size: 24,
                                                                  color:
                                                                      Colors
                                                                          .blue
                                                                          .shade300,
                                                                ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 16),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            user['username'],
                                                            style: TextStyle(
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                              color:
                                                                  Colors
                                                                      .grey
                                                                      .shade800,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            height: 4,
                                                          ),
                                                          Text(
                                                            user['email'],
                                                            style: TextStyle(
                                                              fontSize: 14,
                                                              color:
                                                                  Colors
                                                                      .grey
                                                                      .shade600,
                                                            ),
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    Icon(
                                                      Icons.chevron_right,
                                                      color:
                                                          Colors.blue.shade300,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                ],
                              ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
