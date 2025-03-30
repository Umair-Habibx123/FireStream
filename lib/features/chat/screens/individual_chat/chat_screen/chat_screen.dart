import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:chat_app/features/chat/screens/individual_chat/user_detail/user_detail_page.dart';
import 'widgets/chat_app_bar.dart';
import 'widgets/message_bubble.dart';
import 'widgets/image_bubble.dart';
import 'widgets/message_input.dart';
import 'widgets/image_preview_screen.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String currentUserEmail;
  final String otherParticipantEmail;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.currentUserEmail,
    required this.otherParticipantEmail,
  });

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final List<File> _selectedImages = [];
  late Future<String?> _profileUrlFuture;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _profileUrlFuture = _getProfilePicture(widget.otherParticipantEmail);
  }

  Future<String?> _getProfilePicture(String email) async {
    try {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(email).get();
      return userDoc['profilePic'];
    } catch (e) {
      return null;
    }
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage();
      for (XFile pickedFile in pickedFiles) {
        _selectedImages.add(File(pickedFile.path));
      }
      setState(() {});
    } catch (e) {
      print('Failed to pick images: $e');
    }
  }

  Future<String?> _uploadImage(File imageFile) async {
    setState(() => _isUploading = true);
    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      TaskSnapshot uploadTask = await FirebaseStorage.instance
          .ref('chat_images/$fileName')
          .putFile(imageFile);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      print('Failed to upload image: $e');
      return null;
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _removeImage(int index) {
    setState(() => _selectedImages.removeAt(index));
  }

  void _viewImage(String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImagePreviewScreen(imageUrl: imageUrl),
      ),
    );
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty && _selectedImages.isEmpty)
      return;

    setState(() => _isUploading = true);

    try {
      List<String> uploadedImageUrls = [];
      for (File imageFile in _selectedImages) {
        String? imageUrl = await _uploadImage(imageFile);
        if (imageUrl != null) uploadedImageUrls.add(imageUrl);
      }

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .add({
            'text': _messageController.text.trim(),
            'sender': widget.currentUserEmail,
            'timestamp': FieldValue.serverTimestamp(),
            'imageUrls': uploadedImageUrls,
          });

      final chatRef = FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId);
      final chatDoc = await chatRef.get();

      if (chatDoc.exists && chatDoc.data()?['deletedBy'] != null) {
        List<dynamic> deletedByArray =
            chatDoc.data()?['deletedBy'] as List<dynamic>;
        if (deletedByArray.contains(widget.otherParticipantEmail)) {
          await chatRef.update({
            'deletedBy': FieldValue.arrayRemove([widget.otherParticipantEmail]),
          });
        }
      }

      _messageController.clear();
      _selectedImages.clear();
    } catch (e) {
      print('Failed to send message: $e');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _deleteMessage(String messageId) async {
    try {
      DocumentSnapshot messageSnapshot =
          await FirebaseFirestore.instance
              .collection('chats')
              .doc(widget.chatId)
              .collection('messages')
              .doc(messageId)
              .get();

      if (messageSnapshot.exists) {
        List<dynamic> imageUrls = messageSnapshot['imageUrls'] ?? [];
        for (String imageUrl in imageUrls) {
          String path = imageUrl.split('?')[0];
          await FirebaseStorage.instance
              .refFromURL(Uri.decodeFull(path))
              .delete();
        }

        await FirebaseFirestore.instance
            .collection('chats')
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
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Message'),
            content: const Text(
              'Are you sure you want to delete this message?',
            ),
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
          ),
    );
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Now';
    DateTime dateTime = timestamp.toDate();
    DateTime now = DateTime.now();

    if (dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day) {
      return "${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}";
    } else {
      return "${_monthNames[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}";
    }
  }

  void _showTextOptions(BuildContext context, String text, String messageId) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text("Copy"),
              onTap: () {
                Clipboard.setData(ClipboardData(text: text));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Text copied to clipboard.")),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.forward),
              title: const Text("Forward"),
              onTap: () {
                Navigator.pop(context);
                _forwardMessage(text, isImage: false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text("Delete"),
              onTap: () async {
                Navigator.pop(context);
                _showDeleteConfirmation(messageId);
              },
            ),
          ],
        );
      },
    );
  }

  void _showImageOptions(
    BuildContext context,
    List<dynamic> imageUrls,
    String messageId,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.forward),
              title: const Text("Forward"),
              onTap: () {
                Navigator.pop(context);
                _forwardMessage(imageUrls, isImage: true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text("Save"),
              onTap: () async {
                Navigator.pop(context);
                for (var imageUrl in imageUrls) {
                  await _saveImage(imageUrl);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text("Delete"),
              onTap: () async {
                Navigator.pop(context);
                _showDeleteConfirmation(messageId);
              },
            ),
          ],
        );
      },
    );
  }

  void _forwardMessage(dynamic content, {required bool isImage}) {
    // Implement your forwarding logic here
    print(
      isImage ? "Forwarding images: $content" : "Forwarding text: $content",
    );
  }

  Future<void> _saveImage(String imageUrl) async {
    try {
      // Step 1: Let the user select a folder
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

      if (selectedDirectory == null) {
        // User canceled the picker
        print("Folder selection canceled.");
        return;
      }

      print("Selected folder: $selectedDirectory");

      // Step 2: Download the image
      Dio dio = Dio();
      String fileName =
          imageUrl.split('/').last.split('?').first; // Extract file name
      String savePath = '$selectedDirectory/$fileName';

      print("Saving image to: $savePath");

      // Download and save the image
      await dio.download(imageUrl, savePath);

      print("Image saved successfully to $savePath");
    } catch (e) {
      print("Error saving image: $e");
    }
  }

  final List<String> _monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: ChatAppBar(
        profileUrlFuture: _profileUrlFuture,
        otherParticipantEmail: widget.otherParticipantEmail,
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => UserDetailPage(
                      email: widget.otherParticipantEmail,
                      currentUserEmail: widget.currentUserEmail,
                    ),
              ),
            ),
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
                        .collection('chats')
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

                  return ListView.builder(
                    reverse: true,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var message = snapshot.data!.docs[index];
                      bool isSentByCurrentUser =
                          message['sender'] == widget.currentUserEmail;

                      return GestureDetector(
                        onLongPress: () {
                          if (message['text'] != null &&
                              message['text'].isNotEmpty) {
                            _showTextOptions(
                              context,
                              message['text'],
                              message.id,
                            );
                          } else if (message['imageUrls'] != null) {
                            _showImageOptions(
                              context,
                              message['imageUrls'],
                              message.id,
                            );
                          }
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: Column(
                            crossAxisAlignment:
                                isSentByCurrentUser
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                            children: [
                              if (message['imageUrls'] != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: ImageBubble(
                                    imageUrls: message['imageUrls'],
                                    onImageTap: _viewImage,
                                  ),
                                ),
                              if (message['text'] != null &&
                                  message['text'].isNotEmpty)
                                MessageBubble(
                                  text: message['text'],
                                  isSentByCurrentUser: isSentByCurrentUser,
                                ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Text(
                                  _formatTimestamp(message['timestamp']),
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 11,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
          MessageInput(
            messageController: _messageController,
            selectedImages: _selectedImages,
            isUploading: _isUploading,
            onPickImages: _pickImages,
            onRemoveImage: _removeImage,
            onSendMessage: _sendMessage,
          ),
        ],
      ),
    );
  }
}
