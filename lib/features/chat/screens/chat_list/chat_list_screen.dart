import 'package:chat_app/features/authentication/ProfileSetting/ProfileScreen.dart';
import 'package:chat_app/features/chat/screens/group_chat/create_chat/addGroupChatScreen.dart';
import 'package:chat_app/features/chat/screens/individual_chat/add_chat/addchatScreen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'widgets/individual_chat_list.dart';
import 'widgets/group_chat_list.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen>
    with SingleTickerProviderStateMixin, RouteAware {
  String _currentUserEmail = "";
  late TabController _tabController;
  String? _photoURL;
  bool _isLoading = true;

  @override
  void didPopNext() {
    _loadUserPhoto();
  }

  Future<void> _loadUserPhoto() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? photoURL = prefs.getString('userPhoto');
    setState(() {
      _photoURL = photoURL;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadCurrentUserEmail();
    _loadUserPhoto();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUserEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUserEmail = prefs.getString('userEmail') ?? '';
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'FireStream',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
            letterSpacing: 1.2,
          ),
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 4,
        shadowColor: Colors.blueAccent.withOpacity(0.3),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
              child: CircleAvatar(
                backgroundImage: _photoURL != null 
                    ? NetworkImage(_photoURL!) 
                    : null,
                radius: 18,
                backgroundColor: Colors.white.withOpacity(0.3),
                child: _photoURL == null
                    ? const Icon(Icons.person, color: Colors.white)
                    : null,
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.normal,
          ),
          tabs: const [
            Tab(text: 'Chats'),
            Tab(text: 'Groups'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                strokeWidth: 2.5,
              ),
            )
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.blueAccent.withOpacity(0.05),
                    Colors.blueAccent.withOpacity(0.02),
                  ],
                ),
              ),
              child: TabBarView(
                controller: _tabController,
                children: [
                  IndividualChatList(currentUserEmail: _currentUserEmail),
                  GroupChatList(currentUserEmail: _currentUserEmail),
                ],
              ),
            ),
      floatingActionButton: _isLoading
          ? null
          : Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FloatingActionButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddGroupChatScreen(),
                      ),
                    );
                  },
                  backgroundColor: Colors.blueAccent,
                  elevation: 4,
                  child: const Icon(Icons.group_add, size: 28),
                ),
                const SizedBox(height: 16),
                FloatingActionButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddNewChatScreen(),
                      ),
                    );
                  },
                  backgroundColor: Colors.blueAccent,
                  elevation: 4,
                  child: const Icon(Icons.message, size: 28),
                ),
              ],
            ),
    );
  }
}
