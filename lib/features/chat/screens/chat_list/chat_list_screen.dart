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
  String _username = "";
  late TabController _tabController;
  String? _photoURL;
  bool _isLoading = true;

  @override
  void didPopNext() {
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _photoURL = prefs.getString('userPhoto');
      _username = prefs.getString('userName') ?? '';
    });
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCurrentUserEmail();
    _loadUserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUserEmail = prefs.getString('userEmail') ?? '';
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          // ── 1. Hero header (expandable, no tab bar inside) ──────────────
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            snap: false,
            elevation: 0,
            // KEY FIX: explicit background colour so collapsed state matches
            backgroundColor: const Color(0xFF1565C0),
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 16, 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Hey, ${_username.isNotEmpty ? _username.split(' ').first : 'there'} 👋',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Messages',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ProfileScreen()),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.4),
                                  width: 2),
                            ),
                            child: CircleAvatar(
                              radius: 22,
                              backgroundColor: Colors.white.withOpacity(0.2),
                              backgroundImage: _photoURL != null &&
                                      _photoURL!.isNotEmpty
                                  ? NetworkImage(_photoURL!)
                                  : null,
                              child:
                                  (_photoURL == null || _photoURL!.isEmpty)
                                      ? const Icon(Icons.person_rounded,
                                          color: Colors.white, size: 24)
                                      : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── 2. Tab bar as its own pinned sliver — CLEAN separation ──────
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                indicatorSize: TabBarIndicatorSize.label,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white.withOpacity(0.55),
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  letterSpacing: 0.3,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                ),
                tabs: const [
                  Tab(text: 'Chats'),
                  Tab(text: 'Groups'),
                ],
              ),
            ),
          ),
        ],
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF1565C0),
                  strokeWidth: 2.5,
                ),
              )
            : TabBarView(
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
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _fabButton(
                  icon: Icons.group_add_rounded,
                  tooltip: 'New Group',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AddGroupChatScreen()),
                  ),
                  isSecondary: true,
                ),
                const SizedBox(height: 12),
                _fabButton(
                  icon: Icons.edit_rounded,
                  tooltip: 'New Chat',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AddNewChatScreen()),
                  ),
                  isSecondary: false,
                ),
              ],
            ),
    );
  }

  Widget _fabButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    required bool isSecondary,
  }) {
    if (isSecondary) {
      return FloatingActionButton.small(
        heroTag: tooltip,
        onPressed: onTap,
        tooltip: tooltip,
        backgroundColor: Colors.white,
        elevation: 3,
        child: Icon(icon, color: const Color(0xFF1565C0), size: 20),
      );
    }
    return FloatingActionButton(
      heroTag: tooltip,
      onPressed: onTap,
      tooltip: tooltip,
      backgroundColor: const Color(0xFF1565C0),
      elevation: 4,
      child: Icon(icon, color: Colors.white, size: 24),
    );
  }
}

// ── Delegate that gives the TabBar its own persistent sliver slot ─────────────
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  const _TabBarDelegate(this.tabBar);

  final TabBar tabBar;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: const Color(0xFF1565C0),
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) =>
      tabBar != oldDelegate.tabBar;
}