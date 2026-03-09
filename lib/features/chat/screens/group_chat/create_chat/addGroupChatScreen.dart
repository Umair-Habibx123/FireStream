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
  final FocusNode _nameFocus = FocusNode();
  String _currentUserEmail = "";
  File? _groupPhoto;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserEmail();
    _nameFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _currentUserEmail = prefs.getString('userEmail') ?? '');
  }

  Future<void> _pickGroupPhoto() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _groupPhoto = File(pickedFile.path));
    }
  }

  Future<void> _createGroupChat() async {
    final groupName = _groupNameController.text.trim();
    if (groupName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a group name'),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final chatRef =
          await FirebaseFirestore.instance.collection('groupChats').add({
        'groupName': groupName,
        'isGroup': true,
        'chatType': 'group',
        'SettingOnlyAdmin': true,
        'MessagesOnlyAdmin': false,
        'AddMembersBy': 'anyone',
        'groupPhotoUrl': '',
        'participants': [_currentUserEmail],
        'createdBy': _currentUserEmail,
        'admins': [_currentUserEmail],
        'createdDate': FieldValue.serverTimestamp(),
      });

      if (_groupPhoto != null) {
        final photoUrl = await _uploadGroupPhoto(chatRef.id);
        await chatRef.update({'groupPhotoUrl': photoUrl});
      }

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating group: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red.shade600,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<String> _uploadGroupPhoto(String chatId) async {
    try {
      final fileName =
          'group_profile_pictures/$chatId/${DateTime.now().millisecondsSinceEpoch}.png';
      await FirebaseStorage.instance.ref(fileName).putFile(_groupPhoto!);
      return await FirebaseStorage.instance.ref(fileName).getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading photo: $e');
      return '';
    }
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
        title: const Text(
          'New Group',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
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
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF1565C0),
                strokeWidth: 2.5,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Avatar picker
                  GestureDetector(
                    onTap: _pickGroupPhoto,
                    child: Stack(
                      children: [
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.blue.shade50,
                            border: Border.all(
                              color: const Color(0xFF1565C0).withOpacity(0.3),
                              width: 2.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    const Color(0xFF1565C0).withOpacity(0.15),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(55),
                            child: _groupPhoto != null
                                ? Image.file(_groupPhoto!, fit: BoxFit.cover)
                                : Icon(Icons.group_rounded,
                                    size: 46,
                                    color: const Color(0xFF1565C0)
                                        .withOpacity(0.5)),
                          ),
                        ),
                        Positioned(
                          bottom: 2,
                          right: 2,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1565C0),
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.camera_alt_rounded,
                                size: 15, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _groupPhoto != null ? 'Change photo' : 'Add group photo',
                    style: TextStyle(
                      color: const Color(0xFF1565C0).withOpacity(0.8),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Group name field
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _nameFocus.hasFocus
                            ? const Color(0xFF1565C0).withOpacity(0.4)
                            : Colors.transparent,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _nameFocus.hasFocus
                              ? const Color(0xFF1565C0).withOpacity(0.1)
                              : Colors.black.withOpacity(0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _groupNameController,
                      focusNode: _nameFocus,
                      textCapitalization: TextCapitalization.words,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF1A1A2E),
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Group Name',
                        labelStyle: TextStyle(
                          color: _nameFocus.hasFocus
                              ? const Color(0xFF1565C0)
                              : Colors.grey.shade500,
                          fontSize: 14,
                        ),
                        hintText: 'e.g. Family, Work Team...',
                        hintStyle: TextStyle(
                            color: Colors.grey.shade400, fontSize: 14),
                        prefixIcon: Icon(
                          Icons.group_rounded,
                          color: _nameFocus.hasFocus
                              ? const Color(0xFF1565C0)
                              : Colors.grey.shade400,
                          size: 20,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 18),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Helper text
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            size: 13, color: Colors.grey.shade400),
                        const SizedBox(width: 5),
                        Text(
                          'You can add members after creating the group',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade400),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Create button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _createGroupChat,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1565C0),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        shadowColor:
                            const Color(0xFF1565C0).withOpacity(0.4),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.group_add_rounded, size: 20),
                          SizedBox(width: 10),
                          Text(
                            'Create Group',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}