import 'package:chat_app/features/chat/screens/group_chat/group_admins/GroupAdminScreen.dart';
import 'package:chat_app/features/chat/screens/group_chat/group_setting/dialogs/add_admin_dialog.dart';
import 'package:chat_app/features/chat/screens/group_chat/group_setting/dialogs/add_member_dialog.dart';
import 'package:chat_app/features/chat/screens/group_chat/group_setting/dialogs/add_members_by_dialog.dart';
import 'package:chat_app/features/chat/screens/group_chat/group_setting/dialogs/admin_settings_dialog.dart';
import 'package:chat_app/features/chat/screens/group_chat/group_setting/dialogs/change_group_name_dialog.dart';
import 'package:chat_app/features/chat/screens/group_chat/group_setting/dialogs/delete_group_dialog.dart';
import 'package:chat_app/features/chat/screens/group_chat/group_setting/dialogs/messages_settings_dialog.dart';
import 'package:chat_app/features/chat/screens/group_chat/group_setting/widgets/chat_settings_app_bar.dart';
import 'package:chat_app/features/chat/screens/group_chat/group_setting/widgets/group_photo_editor.dart';
import 'package:chat_app/features/chat/screens/group_chat/group_setting/widgets/settings_option_tile.dart';
import 'package:chat_app/features/chat/screens/group_chat/group_participants/GroupParticipantsScreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ChatSettingsScreen extends StatefulWidget {
  final String chatId;

  const ChatSettingsScreen({super.key, required this.chatId});

  @override
  _ChatSettingsScreenState createState() => _ChatSettingsScreenState();
}

class _ChatSettingsScreenState extends State<ChatSettingsScreen> {
  final TextEditingController _newGroupNameController = TextEditingController();
  String? _newGroupPhotoUrl;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isPhotoLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentGroupData(widget.chatId);
  }

  Future<void> _loadCurrentGroupData(String chatId) async {
    setState(() => _isLoading = true);

    try {
      DocumentSnapshot groupChatDoc =
          await FirebaseFirestore.instance
              .collection('groupChats')
              .doc(chatId)
              .get();
      if (groupChatDoc.exists) {
        setState(() {
          _newGroupNameController.text = groupChatDoc['groupName'] ?? '';
          _newGroupPhotoUrl = groupChatDoc['groupPhotoUrl'];
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to load group data: ${e.toString()}";
      });
    } finally {
      setState(() {
        _isLoading = false;
        _isPhotoLoading = false;
      });
    }
  }

  Future<void> _pickGroupPhoto() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() => _newGroupPhotoUrl = pickedFile.path);

      String? uploadedUrl = await _uploadGroupPhoto(pickedFile.path);

      if (uploadedUrl != null) {
        await FirebaseFirestore.instance
            .collection('groupChats')
            .doc(widget.chatId)
            .update({'groupPhotoUrl': uploadedUrl});

        setState(() => _newGroupPhotoUrl = uploadedUrl);
      }
    }
  }

  Future<String?> _uploadGroupPhoto(String filePath) async {
    try {
      DocumentSnapshot groupChatDoc =
          await FirebaseFirestore.instance
              .collection('groupChats')
              .doc(widget.chatId)
              .get();

      if (groupChatDoc.exists && groupChatDoc['groupPhotoUrl'] != null) {
        String existingPhotoUrl = groupChatDoc['groupPhotoUrl'];
        await _deleteExistingPhoto(existingPhotoUrl);
      }

      final storageRef = FirebaseStorage.instance.ref();
      String fileName =
          'group_profile_pictures/${widget.chatId}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final photoRef = storageRef.child(fileName);

      await photoRef.putFile(File(filePath));
      return await photoRef.getDownloadURL();
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to upload photo: ${e.toString()}";
      });
      return null;
    }
  }

  Future<void> _deleteExistingPhoto(String photoUrl) async {
    if (photoUrl.isEmpty) return;

    try {
      final ref = FirebaseStorage.instance.refFromURL(photoUrl);
      await ref.delete();
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to delete the existing photo: ${e.toString()}";
      });
    }
  }

  Future<void> _showAddParticipantDialog() async {
    await showDialog(
      context: context,
      builder:
          (context) => AddMemberDialog(
            chatId: widget.chatId,
            onAddMember: (email) async {
              DocumentSnapshot userDoc =
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(email)
                      .get();

              if (userDoc.exists) {
                await FirebaseFirestore.instance
                    .collection('groupChats')
                    .doc(widget.chatId)
                    .update({
                      'participants': FieldValue.arrayUnion([email]),
                    });
              } else {
                throw "This email is not registered.";
              }
            },
          ),
    );
  }

  Future<void> _showAddAdminDialog() async {
    await showDialog(
      context: context,
      builder:
          (context) => AddAdminDialog(
            chatId: widget.chatId,
            onAddAdmin: (email) async {
              DocumentSnapshot userDoc =
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(email)
                      .get();

              if (userDoc.exists) {
                await FirebaseFirestore.instance
                    .collection('groupChats')
                    .doc(widget.chatId)
                    .update({
                      'admins': FieldValue.arrayUnion([email]),
                      'participants': FieldValue.arrayUnion([email]),
                    });
              } else {
                throw "This email is not registered.";
              }
            },
          ),
    );
  }

  Future<void> _showChangeGroupNameDialog() async {
    await showDialog(
      context: context,
      builder:
          (context) => ChangeGroupNameDialog(
            currentName: _newGroupNameController.text,
            onSave: (newName) async {
              setState(() => _isLoading = true);
              try {
                await FirebaseFirestore.instance
                    .collection('groupChats')
                    .doc(widget.chatId)
                    .update({'groupName': newName});

                setState(() => _newGroupNameController.text = newName);
              } catch (e) {
                throw "Failed to update group name: ${e.toString()}";
              } finally {
                setState(() => _isLoading = false);
              }
            },
          ),
    );
  }

  Future<void> _showMessagesSettingsDialog() async {
    await showDialog(
      context: context,
      builder:
          (context) => MessagesSettingsDialog(
            chatId: widget.chatId,
            onSave: (value) async {
              await FirebaseFirestore.instance
                  .collection('groupChats')
                  .doc(widget.chatId)
                  .update({'MessagesOnlyAdmin': value});
            },
          ),
    );
  }

  Future<void> _showAdminSettingsDialog() async {
    await showDialog(
      context: context,
      builder:
          (context) => AdminSettingsDialog(
            chatId: widget.chatId,
            onSave: (value) async {
              await FirebaseFirestore.instance
                  .collection('groupChats')
                  .doc(widget.chatId)
                  .update({'SettingOnlyAdmin': value});
            },
          ),
    );
  }

  Future<void> _showAddMembersByDialog() async {
    await showDialog(
      context: context,
      builder:
          (context) => AddMembersByDialog(
            chatId: widget.chatId,
            onSave: (value) async {
              await FirebaseFirestore.instance
                  .collection('groupChats')
                  .doc(widget.chatId)
                  .update({'AddMembersBy': value});
            },
          ),
    );
  }

  Future<void> _showDeleteGroupConfirmationDialog() async {
    await showDialog(
      context: context,
      builder: (context) => DeleteGroupDialog(onDelete: _deleteGroup),
    );
  }

  Future<void> _deleteGroup() async {
    try {
      DocumentSnapshot chatDoc =
          await FirebaseFirestore.instance
              .collection('groupChats')
              .doc(widget.chatId)
              .get();

      final chatRef = FirebaseFirestore.instance
          .collection('groupChats')
          .doc(widget.chatId);

      String? groupPhotoUrl = chatDoc['groupPhotoUrl'] as String?;

      if (groupPhotoUrl != null && groupPhotoUrl.isNotEmpty) {
        await FirebaseStorage.instance.refFromURL(groupPhotoUrl).delete();
      }

      var messagesSnapshot = await chatRef.collection('messages').get();

      for (var messageDoc in messagesSnapshot.docs) {
        var messageData = messageDoc.data();

        if (messageData['imageUrls'] != null &&
            messageData['imageUrls'] is List) {
          List<String> imageUrls = List<String>.from(messageData['imageUrls']);

          for (var imageUrl in imageUrls) {
            try {
              await FirebaseStorage.instance.refFromURL(imageUrl).delete();
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error deleting image: $e'),
                  duration: const Duration(seconds: 3),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }
      }

      await chatRef.delete();
      setState(() => _errorMessage = null);

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to delete group: ${e.toString()}";
      });
    }
  }

  void _showGroupAdminDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminsScreen(chatId: widget.chatId),
      ),
    );
  }

  void _showGroupParticipantsDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ParticipantsScreen(chatId: widget.chatId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ChatSettingsAppBar(),
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
                : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 24),
                        GroupPhotoEditor(
                          photoUrl: _newGroupPhotoUrl,
                          isLoading: _isPhotoLoading,
                          onPickPhoto: _pickGroupPhoto,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _newGroupNameController.text,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildSettingsSection("Group Settings", [
                          SettingsOptionTile(
                            title: "Change Group Name",
                            icon: Icons.edit,
                            onTap: _showChangeGroupNameDialog,
                          ),
                          SettingsOptionTile(
                            title: "Admin Settings",
                            icon: Icons.admin_panel_settings,
                            onTap: _showAdminSettingsDialog,
                          ),
                          SettingsOptionTile(
                            title: "Message Settings",
                            icon: Icons.message,
                            onTap: _showMessagesSettingsDialog,
                          ),
                          SettingsOptionTile(
                            title: "Who can Add Members",
                            icon: Icons.add,
                            onTap: _showAddMembersByDialog,
                          ),
                        ]),
                        const SizedBox(height: 16),
                        _buildSettingsSection("Members", [
                          SettingsOptionTile(
                            title: "Add Member",
                            icon: Icons.person_add,
                            onTap: _showAddParticipantDialog,
                          ),
                          SettingsOptionTile(
                            title: "Add Admin",
                            icon: Icons.admin_panel_settings,
                            onTap: _showAddAdminDialog,
                          ),
                          SettingsOptionTile(
                            title: "View Participants",
                            icon: Icons.people,
                            onTap: _showGroupParticipantsDialog,
                          ),
                          SettingsOptionTile(
                            title: "View Admins",
                            icon: Icons.admin_panel_settings,
                            onTap: _showGroupAdminDialog,
                          ),
                        ]),
                        const SizedBox(height: 16),
                        _buildSettingsSection("Danger Zone", [
                          SettingsOptionTile(
                            title: "Delete Group",
                            icon: Icons.delete_forever,
                            onTap: _showDeleteGroupConfirmationDialog,
                            isDestructive: true,
                          ),
                        ]),
                        if (_errorMessage != null)
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.red.shade100,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: Colors.red.shade400,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: TextStyle(
                                      color: Colors.red.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
      ),
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
          child: Column(children: options),
        ),
      ],
    );
  }
}
