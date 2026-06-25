import 'package:chat_app/features/chat/screens/group_chat/chat_screen/widgets/group_chat_app_bar.dart';
import 'package:chat_app/features/chat/screens/group_chat/chat_screen/widgets/group_image_preview_screen.dart';
import 'package:chat_app/features/chat/screens/group_chat/chat_screen/widgets/group_message_bubble.dart';
import 'package:chat_app/features/chat/screens/group_chat/chat_screen/widgets/group_message_input.dart';
import 'package:chat_app/features/services/scheduled_message_service.dart';
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

class _GroupChatScreenState extends State<GroupChatScreen>
    with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final List<File> _selectedImages = [];

  bool _isUploading = false;
  bool _canSendMessages = true;
  bool _messagesOnlyAdmin = false;
  late final ScheduledMessageService _scheduler;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchAdminSettings();
    _scheduler = ScheduledMessageService(widget.currentUserEmail)..start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scheduler.stop();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _fetchAdminSettings() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('groupChats')
          .doc(widget.chatId)
          .get();

      _messagesOnlyAdmin = doc['MessagesOnlyAdmin'] ?? false;

      if (_messagesOnlyAdmin) {
        List<String> admins = List<String>.from(doc['admins'] ?? []);
        _canSendMessages = admins.contains(widget.currentUserEmail);
      }

      setState(() {});
    } catch (e) {
      debugPrint('Failed to fetch admin settings: $e');
    }
  }

  void _sendMessage() async {
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
          .collection('groupChats')
          .doc(widget.chatId)
          .collection('messages')
          .add({
        'text': _messageController.text.trim(),
        'sender': widget.currentUserEmail,
        'timestamp': FieldValue.serverTimestamp(),
        'imageUrls': uploadedImageUrls,
      });

      // Update last message on group doc
      await FirebaseFirestore.instance
          .collection('groupChats')
          .doc(widget.chatId)
          .update({
        'lastMessage': _messageController.text.trim().isNotEmpty
            ? _messageController.text.trim()
            : '📷 Photo',
        'timestamp': FieldValue.serverTimestamp(),
      });

      _messageController.clear();
      _selectedImages.clear();
    } catch (e) {
      debugPrint('Failed to send message: $e');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage();
      for (XFile f in pickedFiles) {
        _selectedImages.add(File(f.path));
      }
      setState(() {});
    } catch (e) {
      debugPrint('Failed to pick images: $e');
    }
  }

  Future<String?> _uploadImage(File imageFile) async {
    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      TaskSnapshot task = await FirebaseStorage.instance
          .ref('chat_images/$fileName')
          .putFile(imageFile);
      return await task.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Failed to upload image: $e');
      return null;
    }
  }

  void _removeImage(int index) =>
      setState(() => _selectedImages.removeAt(index));

  /// Attachment chooser (gallery / document / video-audio).
  void _showAttachmentSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _attachOption(Icons.photo_library_rounded, 'Gallery',
                  Colors.purple, () {
                Navigator.pop(ctx);
                _pickImages();
              }),
              _attachOption(Icons.insert_drive_file_rounded, 'Document',
                  Colors.blue, () {
                Navigator.pop(ctx);
                _pickAndSendFiles();
              }),
              _attachOption(Icons.movie_rounded, 'Video / Audio', Colors.orange,
                  () {
                Navigator.pop(ctx);
                _pickAndSendFiles();
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _attachOption(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  /// Uploads a recorded voice note and posts it as an audio message.
  Future<void> _sendAudio(String path) async {
    setState(() => _isUploading = true);
    try {
      final fileName = 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      final snap = await FirebaseStorage.instance
          .ref('chat_audio/$fileName')
          .putFile(File(path));
      final url = await snap.ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('groupChats')
          .doc(widget.chatId)
          .collection('messages')
          .add({
        'text': '',
        'sender': widget.currentUserEmail,
        'timestamp': FieldValue.serverTimestamp(),
        'imageUrls': [],
        'audioUrl': url,
      });
      await FirebaseFirestore.instance
          .collection('groupChats')
          .doc(widget.chatId)
          .update({
        'lastMessage': '🎤 Voice message',
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Failed to send audio: $e');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  /// Picks any file type and posts each as a file message.
  Future<void> _pickAndSendFiles() async {
    try {
      final result = await FilePicker.platform
          .pickFiles(allowMultiple: true, type: FileType.any);
      if (result == null) return;
      setState(() => _isUploading = true);
      for (final pf in result.files) {
        if (pf.path == null) continue;
        final name = pf.name;
        final ext = pf.extension ?? name.split('.').last;
        final storageName = '${DateTime.now().millisecondsSinceEpoch}_$name';
        final snap = await FirebaseStorage.instance
            .ref('chat_files/$storageName')
            .putFile(File(pf.path!));
        final url = await snap.ref.getDownloadURL();

        await FirebaseFirestore.instance
            .collection('groupChats')
            .doc(widget.chatId)
            .collection('messages')
            .add({
          'text': '',
          'sender': widget.currentUserEmail,
          'timestamp': FieldValue.serverTimestamp(),
          'imageUrls': [],
          'fileUrl': url,
          'fileName': name,
          'fileType': ext,
        });
        await FirebaseFirestore.instance
            .collection('groupChats')
            .doc(widget.chatId)
            .update({
          'lastMessage': '📎 $name',
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Failed to send file: $e');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  /// Schedule the current text/images for later delivery.
  Future<void> _scheduleMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty && _selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Type a message to schedule')),
      );
      return;
    }
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now.add(const Duration(minutes: 5))),
    );
    if (time == null) return;
    final scheduledFor =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);
    if (scheduledFor.isBefore(DateTime.now())) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pick a time in the future')),
        );
      }
      return;
    }

    setState(() => _isUploading = true);
    final imageUrls = <String>[];
    for (final img in _selectedImages) {
      final url = await _uploadImage(img);
      if (url != null) imageUrls.add(url);
    }
    await ScheduledMessageService.schedule(
      chatId: widget.chatId,
      collection: 'groupChats',
      sender: widget.currentUserEmail,
      text: text,
      imageUrls: imageUrls,
      scheduledFor: scheduledFor,
      toLabel: widget.groupName,
    );
    _messageController.clear();
    _selectedImages.clear();
    if (mounted) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message scheduled')),
      );
    }
  }

  void _viewImage(String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => GroupImagePreviewScreen(imageUrl: imageUrl)),
    );
  }

  void _deleteMessage(String messageId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('groupChats')
          .doc(widget.chatId)
          .collection('messages')
          .doc(messageId)
          .get();

      if (snapshot.exists) {
        List<dynamic> imageUrls = snapshot['imageUrls'] ?? [];
        for (String url in imageUrls) {
          try {
            await FirebaseStorage.instance
                .refFromURL(Uri.decodeFull(url.split('?')[0]))
                .delete();
          } catch (_) {}
        }

        await FirebaseFirestore.instance
            .collection('groupChats')
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
        title: Text('Delete Message',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to delete this message?'),
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
            child: Text('Delete',
                style: TextStyle(
                    color: Color(0xFFE53935), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
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
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(ctx).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
            if (!isImageMessage && messageText != null)
              _sheetTile(ctx, Icons.copy_rounded, 'Copy', Colors.blueAccent,
                  () {
                Clipboard.setData(ClipboardData(text: messageText));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Copied to clipboard'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    margin: const EdgeInsets.all(16),
                  ),
                );
              }),
            if (isImageMessage && imageUrl != null)
              _sheetTile(
                  ctx, Icons.download_rounded, 'Save', Colors.blueAccent,
                  () async {
                Navigator.pop(ctx);
                await _saveImage(imageUrl);
              }),
            _sheetTile(ctx, Icons.forward_rounded, 'Forward', Colors.teal,
                () => Navigator.pop(ctx)),
            if (isSentByCurrentUser)
              _sheetTile(ctx, Icons.delete_rounded, 'Delete', Colors.red, () {
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
      title: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: label == 'Delete'
              ? const Color(0xFFE53935)
              : Theme.of(context).colorScheme.onSurface,
        ),
      ),
      onTap: onTap,
    );
  }

  void _showUserInfo(String email) async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(email)
        .get();
    final data = userDoc.data();
    if (data == null || !mounted) return;

    final username = data['username'] as String? ?? email;
    final profilePicUrl = data['profilePic'] as String? ?? '';

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.blue.shade100, width: 2.5),
                ),
                child: CircleAvatar(
                  radius: 44,
                  backgroundColor: Colors.blue.shade50,
                  backgroundImage: profilePicUrl.isNotEmpty
                      ? NetworkImage(profilePicUrl)
                      : null,
                  child: profilePicUrl.isEmpty
                      ? Icon(Icons.person_rounded,
                          size: 44, color: Colors.blue.shade300)
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                username,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  email,
                  style: TextStyle(
                      fontSize: 13, color: Colors.blue.shade700),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveImage(String imageUrl) async {
    try {
      String? dir = await FilePicker.platform.getDirectoryPath();
      if (dir == null) return;
      String fileName = imageUrl.split('/').last.split('?').first;
      await Dio().download(imageUrl, '$dir/$fileName');
    } catch (e) {
      debugPrint('Error saving image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GroupChatAppBar(
        groupName: widget.groupName,
        groupPhotoUrl: widget.groupPhotoUrl,
        chatId: widget.chatId,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('groupChats')
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

                final messages = snapshot.data!.docs;

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.group_outlined,
                            size: 56, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text(
                          'No messages yet',
                          style: TextStyle(
                              color: Colors.grey.shade400, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Be the first to say something! 👋',
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
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMine =
                        message['sender'] == widget.currentUserEmail;
                    final isImageMessage =
                        message['imageUrls'] != null &&
                            (message['imageUrls'] as List).isNotEmpty;

                    final data = message.data() as Map<String, dynamic>;
                    return GroupMessageBubble(
                      messageText: message['text'] ?? '',
                      senderEmail: message['sender'],
                      currentUserEmail: widget.currentUserEmail,
                      imageUrls: message['imageUrls'],
                      audioUrl: data['audioUrl'] as String?,
                      fileUrl: data['fileUrl'] as String?,
                      fileName: data['fileName'] as String?,
                      fileType: data['fileType'] as String?,
                      timestamp: message['timestamp'],
                      onLongPress: (_) => _showMessageOptions(
                        isSentByCurrentUser: isMine,
                        isImageMessage: isImageMessage,
                        messageId: message.id,
                        messageText: message['text'],
                        imageUrl: isImageMessage
                            ? message['imageUrls'][0]
                            : null,
                      ),
                      onUserTap: _showUserInfo,
                      onImageTap: _viewImage,
                    );
                  },
                );
              },
            ),
          ),
          GroupMessageInput(
            messageController: _messageController,
            canSendMessages: _canSendMessages,
            isUploading: _isUploading,
            onSendPressed: _sendMessage,
            onPickImagesPressed: _showAttachmentSheet,
            selectedImages: _selectedImages,
            onRemoveImage: _removeImage,
            onSendAudio: _sendAudio,
            onSchedule: _scheduleMessage,
          ),
        ],
      ),
    );
  }
}