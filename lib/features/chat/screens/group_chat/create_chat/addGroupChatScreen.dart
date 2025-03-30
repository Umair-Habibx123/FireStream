import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class AddGroupChatScreen extends StatefulWidget {
  const AddGroupChatScreen({super.key});

  @override
  _AddGroupChatScreenState createState() => _AddGroupChatScreenState();
}

class _AddGroupChatScreenState extends State<AddGroupChatScreen> {
  final TextEditingController _groupNameController = TextEditingController();
  String _currentUserEmail = "";
  File? _groupPhoto;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false; // Loading state variable

  @override
  void initState() {
    super.initState();
    _loadCurrentUserEmail();
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUserEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUserEmail = prefs.getString('userEmail') ?? '';
    });
  }

  Future<void> _pickGroupPhoto() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _groupPhoto = File(pickedFile.path);
      });
    }
  }

  Future<void> _createGroupChat() async {
    String groupName = _groupNameController.text.trim();
    if (groupName.isEmpty) {
      setState(() {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group name is mandatory')),
        );
      });
      return;
    }

    setState(() {
      _isLoading = true; // Set loading to true
    });

    try {
      // Create the group chat
      DocumentReference chatRef = await FirebaseFirestore.instance
          .collection('groupChats')
          .add({
            'groupName': groupName,
            'isGroup': true,
            'chatType': 'group',
            'SettingOnlyAdmin': true,
            'MessagesOnlyAdmin': false,
            'AddMembersBy': 'anyone',
            'groupPhotoUrl': '', // Placeholder for photo URL
            'participants': [_currentUserEmail],
            'createdBy': _currentUserEmail,
            'admins': [_currentUserEmail],
            'createdDate': FieldValue.serverTimestamp(),
          });

      // If a group photo is selected, upload it and update the chat with the photo URL
      if (_groupPhoto != null) {
        String photoUrl = await _uploadGroupPhoto(chatRef.id);
        await chatRef.update({'groupPhotoUrl': photoUrl});
      }

      Navigator.of(context).pop();
    } catch (e) {
      // Handle errors here
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error creating group: $e')));
    } finally {
      setState(() {
        _isLoading = false; // Set loading to false
      });
    }
  }

  Future<String> _uploadGroupPhoto(String chatId) async {
    // Create a unique file name for the image
    String fileName =
        'group_profile_pictures/$chatId/${DateTime.now().millisecondsSinceEpoch}.png';

    // Upload the image to Firebase Storage
    try {
      await FirebaseStorage.instance.ref(fileName).putFile(_groupPhoto!);

      // Get the download URL
      String downloadUrl =
          await FirebaseStorage.instance.ref(fileName).getDownloadURL();
      return downloadUrl; // Return the download URL
    } catch (e) {
      print("Error uploading photo: $e");
      return ''; // Return an empty string if upload fails
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "New Group",
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
        child: Padding(
          padding: const EdgeInsets.all(24.0),
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
                  : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Group name input
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
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(20),
                            child: TextField(
                              controller: _groupNameController,
                              decoration: InputDecoration(
                                labelText: "Group name",
                                labelStyle: TextStyle(
                                  color: Colors.grey.shade600,
                                ),
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.auto,
                                border: InputBorder.none,
                                hintText: "Enter a group name",
                                hintStyle: TextStyle(
                                  color: Colors.grey.shade400,
                                ),
                              ),
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Group photo picker
                        GestureDetector(
                          onTap: _pickGroupPhoto,
                          child: Stack(
                            children: [
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.blue.shade200,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blue.shade100.withOpacity(
                                        0.3,
                                      ),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(60),
                                  child:
                                      _groupPhoto != null
                                          ? Image.file(
                                            _groupPhoto!,
                                            fit: BoxFit.cover,
                                          )
                                          : Container(
                                            color: Colors.blue.shade50,
                                            child: Icon(
                                              Icons.group_add,
                                              size: 48,
                                              color: Colors.blue.shade300,
                                            ),
                                          ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.blueAccent,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Add group photo",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Create Group button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _createGroupChat,
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.blueAccent,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                              shadowColor: Colors.blue.shade200,
                            ),
                            child: const Text(
                              "Create Group",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
        ),
      ),
    );
  }
}
