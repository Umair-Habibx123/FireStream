import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditBlocklistScreen extends StatefulWidget {
  const EditBlocklistScreen({super.key});

  @override
  _EditBlocklistScreenState createState() => _EditBlocklistScreenState();
}

class _EditBlocklistScreenState extends State<EditBlocklistScreen> {
  final String _currentUserEmail =
      FirebaseAuth.instance.currentUser?.email ?? '';
  List<Map<String, dynamic>> _blocklist = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBlocklist();
  }

  Future<void> _loadBlocklist() async {
    try {
      final blocklistDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(_currentUserEmail)
              .collection('contacts')
              .doc('blockList')
              .get();

      if (blocklistDoc.exists) {
        List<dynamic> blocklist = blocklistDoc['contactEmails'] ?? [];
        List<Map<String, dynamic>> blocklistDetails = [];

        for (String email in blocklist) {
          final userDoc =
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(email)
                  .get();

          if (userDoc.exists) {
            final userData = userDoc.data();
            blocklistDetails.add({
              'email': email,
              'username': userData?['username'] ?? 'Unknown',
              'profilePic': userData?['profilePic'] ?? '',
            });
          }
        }

        setState(() {
          _blocklist = blocklistDetails;
          _isLoading = false;
        });
      } else {
        setState(() {
          _blocklist = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading blocklist: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteFromBlocklist(String email) async {
    try {
      setState(() {
        _isLoading = true;
      });

      final blocklistDocRef = FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUserEmail)
          .collection('contacts')
          .doc('blockList');

      final blocklistDoc = await blocklistDocRef.get();

      if (blocklistDoc.exists) {
        List<dynamic> blocklist = blocklistDoc['contactEmails'] ?? [];
        blocklist.remove(email);

        await blocklistDocRef.update({'contactEmails': blocklist});

        setState(() {
          _blocklist.removeWhere((contact) => contact['email'] == email);
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error deleting from blocklist: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Blocked Users",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.blueAccent, Colors.blue.shade700],
            ),
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(12),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.blue.shade50.withOpacity(0.3)],
          ),
        ),
        child:
            _isLoading
                ? Center(
                  child: CircularProgressIndicator.adaptive(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.blueAccent,
                    ),
                  ),
                )
                : _blocklist.isEmpty
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.block, size: 64, color: Colors.blue.shade200),
                      const SizedBox(height: 16),
                      Text(
                        "No Blocked Users",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Blocked users will appear here",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                )
                : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  itemCount: _blocklist.length,
                  itemBuilder: (context, index) {
                    final blockedContact = _blocklist[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.red.shade100,
                              width: 1.5,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child:
                                blockedContact['profilePic'] != null &&
                                        blockedContact['profilePic'].isNotEmpty
                                    ? Image.network(
                                      blockedContact['profilePic'],
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (_, __, ___) => Icon(
                                            Icons.person,
                                            size: 24,
                                            color: Colors.red.shade300,
                                          ),
                                    )
                                    : Icon(
                                      Icons.person,
                                      size: 24,
                                      color: Colors.red.shade300,
                                    ),
                          ),
                        ),
                        title: Text(
                          blockedContact['username'],
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        subtitle: Text(
                          blockedContact['email'],
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        trailing: IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.red.shade100,
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              Icons.lock_open,
                              size: 20,
                              color: Colors.red.shade400,
                            ),
                          ),
                          onPressed:
                              () =>
                                  _deleteFromBlocklist(blockedContact['email']),
                        ),
                      ),
                    );
                  },
                ),
      ),
    );
  }
}
