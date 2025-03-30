import 'package:chat_app/features/chat/screens/group_chat/chat_screen/widgets/group_chat_app_bar.dart';
import 'package:chat_app/features/chat/screens/group_chat/chat_screen/widgets/group_image_preview_screen.dart';
import 'package:chat_app/features/chat/screens/group_chat/chat_screen/widgets/group_message_bubble.dart';
import 'package:chat_app/features/chat/screens/group_chat/chat_screen/widgets/group_message_input.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';

class GroupChatScreen extends StatefulWidget {
  final String chatId;
  final String currentUserEmail;
  final String groupName;
  final String? groupPhotoUrl;

  const GroupChatScreen({
    super.key,
    required this.chatId,
    required this.currentUserEmail,
    required this.groupName,
    required this.groupPhotoUrl,
  });

  @override
  _GroupChatScreenState createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final List<File> _selectedImages = [];

  bool _isUploading = false;
  bool _canSendMessages = true;
  bool _messagesOnlyAdmin = false;

  @override
  void initState() {
    super.initState();
    _fetchAdminSettings();
  }

  Future<void> _fetchAdminSettings() async {
    try {
      DocumentSnapshot chatSettingsDoc =
          await FirebaseFirestore.instance
              .collection('groupChats')
              .doc(widget.chatId)
              .get();

      _messagesOnlyAdmin = chatSettingsDoc['MessagesOnlyAdmin'] ?? false;

      if (_messagesOnlyAdmin) {
        List<String> adminEmails = List<String>.from(
          chatSettingsDoc['admins'] ?? [],
        );

        _canSendMessages = adminEmails.contains(widget.currentUserEmail);
      }

      setState(() {});
    } catch (e) {
      print('Failed to fetch admin settings: $e');
    }
  }

  void _showMessageOptions({
    required bool isSentByCurrentUser,
    required bool isImageMessage,
    required String messageId,
    String? messageText,
    String? imageUrl,
  }) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Wrap(
          children: [
            if (isImageMessage && imageUrl != null) ...[
              ListTile(
                leading: const Icon(Icons.save_alt),
                title: const Text('Save'),
                onTap: () {
                  Navigator.of(context).pop();
                  _saveImage(imageUrl);
                },
              ),
              ListTile(
                leading: const Icon(Icons.forward),
                title: const Text('Forward'),
                onTap: () {
                  Navigator.of(context).pop();
                  _forwardMessage(imageUrl, isImage: true);
                },
              ),
              if (isSentByCurrentUser)
                ListTile(
                  leading: const Icon(Icons.delete),
                  title: const Text('Delete'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showDeleteConfirmation(messageId);
                  },
                ),
            ] else if (!isImageMessage && messageText != null) ...[
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('Copy'),
                onTap: () {
                  Navigator.of(context).pop();
                  _copyToClipboard(messageText);
                },
              ),
              ListTile(
                leading: const Icon(Icons.forward),
                title: const Text('Forward'),
                onTap: () {
                  Navigator.of(context).pop();
                  _forwardMessage(messageText, isImage: false);
                },
              ),
              if (isSentByCurrentUser)
                ListTile(
                  leading: const Icon(Icons.delete),
                  title: const Text('Delete'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showDeleteConfirmation(messageId);
                  },
                ),
            ],
          ],
        );
      },
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Text copied to clipboard')));
  }

  void _forwardMessage(String content, {required bool isImage}) {
    print(isImage ? 'Forwarding image: $content' : 'Forwarding text: $content');
  }

  Future<void> _saveImage(String imageUrl) async {
    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

      if (selectedDirectory == null) {
        print("Folder selection canceled.");
        return;
      }

      print("Selected folder: $selectedDirectory");

      Dio dio = Dio();
      String fileName = imageUrl.split('/').last.split('?').first;
      String savePath = '$selectedDirectory/$fileName';

      print("Saving image to: $savePath");

      await dio.download(imageUrl, savePath);

      print("Image saved successfully to $savePath");
    } catch (e) {
      print("Error saving image: $e");
    }
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty && _selectedImages.isEmpty) {
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      List<String> uploadedImageUrls = [];

      for (File imageFile in _selectedImages) {
        String? imageUrl = await _uploadImage(imageFile);
        if (imageUrl != null) {
          uploadedImageUrls.add(imageUrl);
        }
      }

      await FirebaseFirestore.instance
          .collection('groupChats')
          .doc(widget.chatId)
          .collection('messages')
          .add({
            'text': _messageController.text.trim(),
            'sender': widget.currentUserEmail,
            'timestamp': FieldValue.serverTimestamp(),
            'imageUrls': uploadedImageUrls,
          });

      _messageController.clear();
      _selectedImages.clear();
    } catch (e) {
      print('Failed to send message: $e');
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage();

      for (XFile pickedFile in pickedFiles) {
        File imageFile = File(pickedFile.path);
        _selectedImages.add(imageFile);
      }

      setState(() {});
    } catch (e) {
      print('Failed to pick images: $e');
    }
  }

  Future<String?> _uploadImage(File imageFile) async {
    setState(() {
      _isUploading = true;
    });

    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      TaskSnapshot uploadTask = await FirebaseStorage.instance
          .ref('chat_images/$fileName')
          .putFile(imageFile);
      String imageUrl = await uploadTask.ref.getDownloadURL();
      return imageUrl;
    } catch (e) {
      print('Failed to upload image: $e');
      return null;
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _viewImage(String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupImagePreviewScreen(imageUrl: imageUrl),
      ),
    );
  }

  void _deleteMessage(String messageId) async {
    try {
      DocumentSnapshot messageSnapshot =
          await FirebaseFirestore.instance
              .collection('groupChats')
              .doc(widget.chatId)
              .collection('messages')
              .doc(messageId)
              .get();

      if (messageSnapshot.exists) {
        List<dynamic> imageUrls = messageSnapshot['imageUrls'] ?? [];

        if (imageUrls.isNotEmpty) {
          for (String imageUrl in imageUrls) {
            String path = imageUrl.split('?')[0];
            String imagePath = Uri.decodeFull(path);

            await FirebaseStorage.instance.refFromURL(imagePath).delete();
          }
        }

        await FirebaseFirestore.instance
            .collection('groupChats')
            .doc(widget.chatId)
            .collection('messages')
            .doc(messageId)
            .delete();
      }
    } catch (e) {
      print('Error deleting message: $e');
    }
  }

  void _showDeleteConfirmation(String messageId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Message'),
          content: const Text('Are you sure you want to delete this message?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _deleteMessage(messageId);
                Navigator.of(context).pop();
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showUserInfo(String email) async {
    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(email).get();
    String username = userDoc['username'];
    String profilePicUrl = userDoc['profilePic'];

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.blue.shade100, width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(40),
                    child:
                        profilePicUrl.isNotEmpty
                            ? Image.network(
                              profilePicUrl,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (_, __, ___) => Icon(
                                    Icons.person,
                                    size: 40,
                                    color: Colors.blue.shade300,
                                  ),
                            )
                            : Icon(
                              Icons.person,
                              size: 40,
                              color: Colors.blue.shade300,
                            ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  username,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  email,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: GroupChatAppBar(
        groupName: widget.groupName,
        groupPhotoUrl: widget.groupPhotoUrl,
        chatId: widget.chatId,
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white, Colors.blue.shade50.withOpacity(0.3)],
                ),
              ),
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('groupChats')
                        .doc(widget.chatId)
                        .collection('messages')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (!snapshot.hasData) {
                    return Center(
                      child: CircularProgressIndicator.adaptive(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.blueAccent,
                        ),
                      ),
                    );
                  }
                  var messages = snapshot.data!.docs;
                  return ListView.builder(
                    reverse: true,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      var message = messages[index];
                      bool isSentByCurrentUser =
                          message['sender'] == widget.currentUserEmail;

                      return GroupMessageBubble(
                        messageText: message['text'] ?? '',
                        senderEmail: message['sender'],
                        currentUserEmail: widget.currentUserEmail,
                        imageUrls: message['imageUrls'],
                        timestamp: message['timestamp'],
                        onLongPress: (_) {
                          bool isImageMessage =
                              message['imageUrls'] != null &&
                              (message['imageUrls'] as List).isNotEmpty;
                          String? imageUrl =
                              isImageMessage ? message['imageUrls'][0] : null;
                          String? messageText = message['text'];
                          _showMessageOptions(
                            isSentByCurrentUser: isSentByCurrentUser,
                            isImageMessage: isImageMessage,
                            messageId: message.id,
                            messageText: messageText,
                            imageUrl: imageUrl,
                          );
                        },
                        onUserTap: _showUserInfo,
                        onImageTap: _viewImage, // Pass the image tap handler
                      );
                    },
                  );
                },
              ),
            ),
          ),
          GroupMessageInput(
            messageController: _messageController,
            canSendMessages: _canSendMessages,
            isUploading: _isUploading,
            onSendPressed: _sendMessage,
            onPickImagesPressed: _pickImages,
            selectedImages: _selectedImages,
            onRemoveImage: _removeImage,
          ),
        ],
      ),
    );
  }
}
