import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditContactsScreen extends StatefulWidget {
  const EditContactsScreen({super.key});

  @override
  _EditContactsScreenState createState() => _EditContactsScreenState();
}

class _EditContactsScreenState extends State<EditContactsScreen> {
  final String _currentUserEmail =
      FirebaseAuth.instance.currentUser?.email ?? '';
  List<Map<String, dynamic>> _contacts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContactslist();
  }

  Future<void> _loadContactslist() async {
    try {
      final contactsDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(_currentUserEmail)
              .collection('contacts')
              .doc('savedContacts')
              .get();

      if (contactsDoc.exists) {
        List<dynamic> contacts = contactsDoc['contactEmails'] ?? [];
        List<Map<String, dynamic>> contactsDetails = [];

        for (String email in contacts) {
          final userDoc =
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(email)
                  .get();

          if (userDoc.exists) {
            final userData = userDoc.data();
            contactsDetails.add({
              'email': email,
              'username': userData?['username'] ?? 'Unknown',
              'profilePic': userData?['profilePic'] ?? '',
            });
          }
        }

        setState(() {
          _contacts = contactsDetails;
          _isLoading = false;
        });
      } else {
        setState(() {
          _contacts = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading Contact list: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteContacts(String email) async {
    try {
      setState(() {
        _isLoading = true;
      });

      final contactsDocRef = FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUserEmail)
          .collection('contacts')
          .doc('savedContacts');

      final contactsDoc = await contactsDocRef.get();

      if (contactsDoc.exists) {
        List<dynamic> contacts = contactsDoc['contactEmails'] ?? [];
        contacts.remove(email);

        await contactsDocRef.update({'contactEmails': contacts});

        setState(() {
          _contacts.removeWhere((contacts) => contacts['email'] == email);
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error deleting from Contact list: $e");
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
          "Manage Contacts",
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
                : _contacts.isEmpty
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 64,
                        color: Colors.blue.shade200,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "No Contacts Found",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Add contacts to see them here",
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
                  itemCount: _contacts.length,
                  itemBuilder: (context, index) {
                    final contact = _contacts[index];
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
                          vertical: 8,
                        ),
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.blue.shade100,
                              width: 1.5,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child:
                                contact['profilePic'] != null &&
                                        contact['profilePic'].isNotEmpty
                                    ? Image.network(
                                      contact['profilePic'],
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (_, __, ___) => Icon(
                                            Icons.person,
                                            size: 24,
                                            color: Colors.blue.shade300,
                                          ),
                                    )
                                    : Icon(
                                      Icons.person,
                                      size: 24,
                                      color: Colors.blue.shade300,
                                    ),
                          ),
                        ),
                        title: Text(
                          contact['username'],
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        subtitle: Text(
                          contact['email'],
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        trailing: IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.red.shade100,
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              Icons.delete_outline,
                              size: 20,
                              color: Colors.red.shade400,
                            ),
                          ),
                          onPressed: () => _deleteContacts(contact['email']),
                        ),
                      ),
                    );
                  },
                ),
      ),
    );
  }
}
