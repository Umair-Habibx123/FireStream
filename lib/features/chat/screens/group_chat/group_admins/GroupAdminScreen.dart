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
  List<String> admins = [];
  List<String> participants = [];
  bool isLoading = true;
  String? errorMessage;
  String? currentUserEmail;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserEmail();
    _loadAdmins();
  }

  Future<void> _loadCurrentUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => currentUserEmail = prefs.getString('userEmail'));
  }

  Future<void> _loadAdmins() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('groupChats')
          .doc(widget.chatId)
          .get();
      setState(() {
        admins = List<String>.from(doc['admins'] ?? []);
        participants = List<String>.from(doc['participants'] ?? []);
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load admins: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _removeAdmin(String email) async {
    try {
      await FirebaseFirestore.instance
          .collection('groupChats')
          .doc(widget.chatId)
          .update({'admins': FieldValue.arrayRemove([email])});

      setState(() => admins.remove(email));

      if (admins.isEmpty) {
        final remaining =
            participants.where((p) => p != email).toList();
        if (remaining.isNotEmpty) {
          await _assignNewAdmin(remaining[0]);
        } else {
          await _deleteGroup();
        }
      }
    } catch (e) {
      setState(() => errorMessage = 'Failed to remove admin: $e');
    }
  }

  Future<void> _assignNewAdmin(String email) async {
    await FirebaseFirestore.instance
        .collection('groupChats')
        .doc(widget.chatId)
        .update({'admins': FieldValue.arrayUnion([email])});
    setState(() => admins.add(email));
  }

  Future<void> _deleteGroup() async {
    await FirebaseFirestore.instance
        .collection('groupChats')
        .doc(widget.chatId)
        .delete();
    if (mounted) Navigator.of(context).pop();
  }

  void _confirmRemove(String email, String username) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Admin',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text('Remove $username from admins?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: TextStyle(color: Colors.grey.shade600)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _removeAdmin(email);
            },
            child: const Text('Remove',
                style: TextStyle(
                    color: Color(0xFFE53935), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          children: [
            const Text(
              'Group Admins',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 17),
            ),
            if (!isLoading)
              Text(
                '${admins.length} admin${admins.length == 1 ? '' : 's'}',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.75), fontSize: 12),
              ),
          ],
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
            ),
          ),
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                  color: Color(0xFF1565C0), strokeWidth: 2.5))
          : errorMessage != null
              ? _buildError()
              : admins.isEmpty
                  ? _buildEmpty()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                      physics: const BouncingScrollPhysics(),
                      itemCount: admins.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) =>
                          _buildAdminTile(admins[index]),
                    ),
    );
  }

  Widget _buildAdminTile(String email) {
    final isCurrentUser = email == currentUserEmail;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(email).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildSkeleton();
        }

        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final username = data?['username'] as String? ?? email;
        final profileUrl = data?['profilePic'] as String? ?? '';

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            leading: Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.blue.shade50,
                  backgroundImage: profileUrl.isNotEmpty
                      ? NetworkImage(profileUrl)
                      : null,
                  child: profileUrl.isEmpty
                      ? Icon(Icons.person_rounded,
                          size: 24, color: Colors.blue.shade300)
                      : null,
                ),
                // Admin crown badge
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFA000),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: const Icon(Icons.star_rounded,
                        size: 10, color: Colors.white),
                  ),
                ),
              ],
            ),
            title: Text(
              username,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14.5,
                color: Color(0xFF1A1A2E),
              ),
            ),
            subtitle: Text(
              email,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              overflow: TextOverflow.ellipsis,
            ),
            trailing: isCurrentUser
                ? Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'You',
                      style: TextStyle(
                        color: Color(0xFF1565C0),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                : GestureDetector(
                    onTap: () => _confirmRemove(email, username),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.remove_moderator_rounded,
                          size: 17, color: Colors.red.shade400),
                    ),
                  ),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
        );
      },
    );
  }

  Widget _buildSkeleton() {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _shimmer(48, 48, radius: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _shimmer(110, 13, radius: 4),
                const SizedBox(height: 6),
                _shimmer(160, 11, radius: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _shimmer(double w, double h, {double radius = 4}) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.admin_panel_settings_outlined,
              size: 52, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            'No admins found',
            style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 16,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 44, color: Colors.red.shade300),
            const SizedBox(height: 12),
            Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}