import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddMemberDialog extends StatefulWidget {
  final String chatId;
  final Function(String) onAddMember;

  const AddMemberDialog({
    super.key,
    required this.chatId,
    required this.onAddMember,
  });

  @override
  AddMemberDialogState createState() => AddMemberDialogState();
}

class AddMemberDialogState extends State<AddMemberDialog> {
  final TextEditingController _emailController = TextEditingController();
  String? _errorMessage;
  bool _isChecking = false;
  String _currentUserEmail = '';

  @override
  void initState() {
    super.initState();
    _loadCurrentUserEmail();
  }

  Future<void> _loadCurrentUserEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUserEmail = prefs.getString('userEmail') ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Add Member/Participant',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _emailController,
              style: GoogleFonts.poppins(),
              decoration: InputDecoration(
                labelText: 'Enter email',
                labelStyle: GoogleFonts.poppins(color: Colors.grey),
                filled: true,
                fillColor: Colors.grey.shade200,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.email, color: Colors.blueAccent),
              ),
            ),
            if (_isChecking)
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: CircularProgressIndicator(),
              ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  _errorMessage!,
                  style: GoogleFonts.poppins(color: Colors.red, fontSize: 14),
                ),
              ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade300,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Save',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter an email';
      });
      return;
    }

    if (email == _currentUserEmail) {
      setState(() {
        _errorMessage = 'You cannot add yourself';
      });
      return;
    }

    setState(() {
      _isChecking = true;
      _errorMessage = null;
    });

    try {
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(email).get();

      if (!userDoc.exists) {
        setState(() {
          _errorMessage = 'No user found with this email';
        });
        return;
      }

      final targetUserBlocklist =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(email)
              .collection('contacts')
              .doc('blockList')
              .get();

      if (targetUserBlocklist.exists &&
          (targetUserBlocklist.data()?['contactEmails'] as List?)?.contains(
                _currentUserEmail,
              ) ==
              true) {
        setState(() {
          _errorMessage = 'This user has blocked you';
        });
        return;
      }

      final currentUserBlocklist =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(_currentUserEmail)
              .collection('contacts')
              .doc('blockList')
              .get();

      if (currentUserBlocklist.exists &&
          (currentUserBlocklist.data()?['contactEmails'] as List?)?.contains(
                email,
              ) ==
              true) {
        setState(() {
          _errorMessage = 'You have blocked this user';
        });
        return;
      }

      final chatDoc =
          await FirebaseFirestore.instance
              .collection('chats')
              .doc(widget.chatId)
              .get();

      final participants = chatDoc.data()?['participants'] as List? ?? [];
      if (participants.contains(email)) {
        setState(() {
          _errorMessage = 'User is already in this group';
        });
        return;
      }

      await widget.onAddMember(email);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}
