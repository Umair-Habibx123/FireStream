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

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final List<File> _selectedImages = [];
  late Future<String?> _profileUrlFuture;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _profileUrlFuture = _getProfilePicture(widget.otherParticipantEmail);
    // Mark current user as online when entering chat
    _setOnlineStatus(true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Mark offline when leaving
    _setOnlineStatus(false);
    _messageController.dispose();
    super.dispose();
  }

  /// Called when the app goes background/foreground
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _setOnlineStatus(true);
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _setOnlineStatus(false);
    }
  }

  /// Updates `isOnline` and `lastSeen` on the current user's Firestore doc.
  /// This is what ChatAppBar's stream reads to show Online / Last seen X ago.
  Future<void> _setOnlineStatus(bool isOnline) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUserEmail)
          .update({
        'isOnline': isOnline,
        if (!isOnline) 'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  Future<String?> _getProfilePicture(String email) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(email)
          .get();
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
      debugPrint('Failed to pick images: $e');
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
      debugPrint('Failed to upload image: $e');
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
        builder: (_) => ImagePreviewScreen(imageUrl: imageUrl),
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

      // Update last message on the chat doc
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .update({
        'lastMessage': _messageController.text.trim().isNotEmpty
            ? _messageController.text.trim()
            : '📷 Photo',
        'timestamp': FieldValue.serverTimestamp(),
      });

      final chatRef =
          FirebaseFirestore.instance.collection('chats').doc(widget.chatId);
      final chatDoc = await chatRef.get();

      if (chatDoc.exists && chatDoc.data()?['deletedBy'] != null) {
        List<dynamic> deletedByArray =
            chatDoc.data()?['deletedBy'] as List<dynamic>;
        if (deletedByArray.contains(widget.otherParticipantEmail)) {
          await chatRef.update({
            'deletedBy':
                FieldValue.arrayRemove([widget.otherParticipantEmail]),
          });
        }
      }

      _messageController.clear();
      _selectedImages.clear();
    } catch (e) {
      debugPrint('Failed to send message: $e');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  

  void _deleteMessage(String messageId) async {
    try {
      DocumentSnapshot messageSnapshot = await FirebaseFirestore.instance
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
      debugPrint('Error deleting message: $e');
    }
  }

  void _showDeleteConfirmation(String messageId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Message',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel',
                style: TextStyle(color: Colors.grey.shade600)),
          ),
          TextButton(
            onPressed: () {
              _deleteMessage(messageId);
              Navigator.of(ctx).pop();
            },
            child: const Text('Delete',
                style: TextStyle(
                    color: Color(0xFFE53935),
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';
    DateTime dt = timestamp.toDate();
    DateTime now = DateTime.now();

    if (dt.year == now.year &&
        dt.month == now.month &&
        dt.day == now.day) {
      return "${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
    } else {
      return "${_monthNames[dt.month - 1]} ${dt.day}";
    }
  }

  void _showTextOptions(BuildContext context, String text, String messageId,
      bool isMine) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            _sheetTile(ctx, Icons.copy_rounded, 'Copy', Colors.blueAccent,
                () {
              Clipboard.setData(ClipboardData(text: text));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Copied to clipboard'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  margin: const EdgeInsets.all(16),
                ),
              );
            }),
            _sheetTile(
                ctx, Icons.forward_rounded, 'Forward', Colors.teal, () {
              Navigator.pop(ctx);
            }),
            if (isMine)
              _sheetTile(
                  ctx, Icons.delete_rounded, 'Delete', Colors.red, () {
                Navigator.pop(ctx);
                _showDeleteConfirmation(messageId);
              }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showImageOptions(BuildContext context, List<dynamic> imageUrls,
      String messageId, bool isMine) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            _sheetTile(
                ctx, Icons.download_rounded, 'Save', Colors.blueAccent,
                () async {
              Navigator.pop(ctx);
              for (var url in imageUrls) {
                await _saveImage(url);
              }
            }),
            _sheetTile(
                ctx, Icons.forward_rounded, 'Forward', Colors.teal, () {
              Navigator.pop(ctx);
            }),
            if (isMine)
              _sheetTile(
                  ctx, Icons.delete_rounded, 'Delete', Colors.red, () {
                Navigator.pop(ctx);
                _showDeleteConfirmation(messageId);
              }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _sheetTile(BuildContext ctx, IconData icon, String label, Color color,
      VoidCallback onTap) {
    return ListTile(
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(label,
          style: TextStyle(
              fontWeight: FontWeight.w500,
              color: label == 'Delete'
                  ? const Color(0xFFE53935)
                  : const Color(0xFF1A1A2E))),
      onTap: onTap,
    );
  }

  Future<void> _saveImage(String imageUrl) async {
    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
      if (selectedDirectory == null) return;

      Dio dio = Dio();
      String fileName = imageUrl.split('/').last.split('?').first;
      await dio.download(imageUrl, '$selectedDirectory/$fileName');
    } catch (e) {
      debugPrint("Error saving image: $e");
    }
  }

  final List<String> _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: ChatAppBar(
        profileUrlFuture: _profileUrlFuture,
        otherParticipantEmail: widget.otherParticipantEmail,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => UserDetailPage(
              email: widget.otherParticipantEmail,
              currentUserEmail: widget.currentUserEmail,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF1565C0),
                      strokeWidth: 2.5,
                    ),
                  );
                }

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded,
                            size: 56,
                            color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text(
                          'No messages yet',
                          style: TextStyle(
                              color: Colors.grey.shade400, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Say hello! 👋',
                          style: TextStyle(
                              color: Colors.grey.shade400, fontSize: 13),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 12),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var message = docs[index];
                    bool isMine =
                        message['sender'] == widget.currentUserEmail;

                    // Check if next message (older, since reversed) is from same sender
                    // to decide whether to show tail
                    bool showTail = true;
                    if (index > 0) {
                      final prevMsg = docs[index - 1];
                      if (prevMsg['sender'] == message['sender']) {
                        showTail = false;
                      }
                    }

                    return GestureDetector(
                      onLongPress: () {
                        if (message['text'] != null &&
                            message['text'].isNotEmpty) {
                          _showTextOptions(
                              context, message['text'], message.id, isMine);
                        } else if (message['imageUrls'] != null) {
                          _showImageOptions(context, message['imageUrls'],
                              message.id, isMine);
                        }
                      },
                      child: Column(
                        crossAxisAlignment: isMine
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          if (message['imageUrls'] != null &&
                              (message['imageUrls'] as List).isNotEmpty)
                            Padding(
                              padding:
                                  EdgeInsets.only(
                                left: isMine ? 48 : 10,
                                right: isMine ? 10 : 48,
                              ),
                              child: ImageBubble(
                                imageUrls: message['imageUrls'],
                                onImageTap: _viewImage,
                              ),
                            ),
                          if (message['text'] != null &&
                              message['text'].isNotEmpty)
                            MessageBubble(
                              text: message['text'],
                              isSentByCurrentUser: isMine,
                              showTail: showTail,
                            ),
                          Padding(
                            padding: EdgeInsets.only(
                              left: isMine ? 0 : 14,
                              right: isMine ? 14 : 0,
                              bottom: 6,
                            ),
                            child: Text(
                              _formatTimestamp(message['timestamp']),
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
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