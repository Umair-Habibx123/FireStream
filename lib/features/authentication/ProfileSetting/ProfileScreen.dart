import 'dart:io';
import 'package:chat_app/features/authentication/ProfileSetting/widgets/edit_blocklist_screen.dart';
import 'package:chat_app/features/authentication/ProfileSetting/widgets/edit_contacts_screen.dart';
import 'package:chat_app/features/authentication/ProfileSetting/widgets/profile_app_bar.dart';
import 'package:chat_app/features/authentication/ProfileSetting/widgets/profile_header.dart';
import 'package:chat_app/features/authentication/ProfileSetting/widgets/profile_options_list.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:chat_app/features/authentication/Others/reset_password_screen.dart';
import 'package:chat_app/features/authentication/SignIn/signin_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late String _photoURL;
  late String _username;
  late String _email;
  final _usernameController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final user = _auth.currentUser;

    if (user != null) {
      setState(() {
        _photoURL = prefs.getString('userPhoto') ?? '';
        _username = prefs.getString('userName') ?? '';
        _email = prefs.getString('userEmail') ?? '';
        _usernameController.text = _username;
        _isLoading = false;
      });
    }
  }

  Future<void> _updateUsername() async {
    final newUsername = _usernameController.text.trim();
    if (newUsername.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();

    await FirebaseFirestore.instance.collection('users').doc(_email).update({
      'username': newUsername,
    });

    await prefs.setString('userName', newUsername);

    setState(() {
      _username = newUsername;
    });
  }

  Future<void> _updateProfilePic() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        final prefs = await SharedPreferences.getInstance();
        final storageRef = FirebaseStorage.instance.ref().child(
          'profile_pictures/${"$_email profile_pic"}.jpg',
        );

        await storageRef.putFile(File(pickedFile.path));
        final downloadUrl = await storageRef.getDownloadURL();

        await FirebaseFirestore.instance.collection('users').doc(_email).update(
          {'profilePic': downloadUrl},
        );

        await prefs.setString('userPhoto', downloadUrl);

        setState(() {
          _photoURL = downloadUrl;
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile picture: $e')),
        );
      }
    }
  }

  Future<void> _updatePassword() async {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const ResetPasswordScreen()),
    );
  }

  Future<void> _logout() async {
    await _auth.signOut();
    GoogleSignIn googleSignIn = GoogleSignIn();
    await googleSignIn.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  Future<void> _editContacts() async {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const EditContactsScreen()));
  }

  Future<void> _editBlocklist() async {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const EditBlocklistScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ProfileAppBar(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.blue.shade50.withOpacity(0.2)],
          ),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                const SizedBox(height: 24),

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ProfileHeader(
                    photoURL: _photoURL,
                    username: _username,
                    email: _email,
                    onEditPhoto: _updateProfilePic,
                    isLoading: _isLoading,
                  ),
                ),
                const SizedBox(height: 24),

                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: ProfileOptionsList(
                      usernameController: _usernameController,
                      onUpdateUsername: _updateUsername,
                      onUpdatePassword: _updatePassword,
                      onEditContacts: _editContacts,
                      onEditBlocklist: _editBlocklist,
                      onLogout: _logout,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
