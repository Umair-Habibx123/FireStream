import 'dart:async';
import 'package:chat_app/features/chat/screens/individual_chat/chat_screen/chat_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class ChatCard extends StatefulWidget {
  final String chatId;
  final String currentUserEmail;
  final String otherParticipant;

  const ChatCard({
    super.key,
    required this.chatId,
    required this.currentUserEmail,
    required this.otherParticipant,
  });

  @override
  _ChatCardState createState() => _ChatCardState();
}

class _ChatCardState extends State<ChatCard> {
  late Stream<Map<String, dynamic>> _latestMessageStream;
  late Future<String?> _profilePictureFuture;
  late Future<bool> _isContactSavedFuture;
  StreamSubscription? _messageSubscription;

  @override
  void initState() {
    super.initState();
    _latestMessageStream = _getLatestMessageStream();
    _profilePictureFuture = _getProfilePicture();
    _isContactSavedFuture = _isContactSaved();
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    super.dispose();
  }

  Stream<Map<String, dynamic>> _getLatestMessageStream() {
    final messagesRef = FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages');
    return messagesRef
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isNotEmpty) {
            final latestMessageDoc = snapshot.docs.first;
            bool hasImages =
                latestMessageDoc['imageUrls'] != null &&
                (latestMessageDoc['imageUrls'] as List).isNotEmpty;

            return {
              'text':
                  hasImages
                      ? '<image>'
                      : (latestMessageDoc['text'] ?? 'No messages yet'),
              'timestamp': latestMessageDoc['timestamp'] as Timestamp?,
            };
          }
          return {'text': 'No messages yet', 'timestamp': null};
        });
  }

  Future<String?> _getProfilePicture() async {
    try {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.otherParticipant)
              .get();

      if (userDoc.exists) {
        return userDoc['profilePic'] ?? '';
      }
      return null;
    } catch (e) {
      debugPrint("Error getting profile picture: $e");
      return null;
    }
  }

  Future<bool> _isContactSaved() async {
    try {
      DocumentSnapshot savedContactsDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.currentUserEmail)
              .collection('contacts')
              .doc('savedContacts')
              .get();

      if (savedContactsDoc.exists) {
        List<dynamic> contactEmails = savedContactsDoc['contactEmails'] ?? [];
        return contactEmails.contains(widget.otherParticipant);
      }
      return false;
    } catch (e) {
      debugPrint("Error checking saved contact: $e");
      return false;
    }
  }

  Future<void> _deleteChat() async {
    try {
      final chatRef = FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId);

      await chatRef.update({
        'deletedBy': FieldValue.arrayUnion([widget.currentUserEmail]),
      });

      final chatDoc = await chatRef.get();
      List<dynamic> deletedBy = chatDoc['deletedBy'] ?? [];

      if (deletedBy.length == 2) {
        var messagesSnapshot = await chatRef.collection('messages').get();

        for (var messageDoc in messagesSnapshot.docs) {
          var messageData = messageDoc.data();

          if (messageData['imageUrls'] != null &&
              messageData['imageUrls'] is List) {
            List<String> imageUrls = List<String>.from(
              messageData['imageUrls'],
            );

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
          await messageDoc.reference.delete();
        }
        await chatRef.delete();
      }
    } catch (e) {
      debugPrint('Error updating chat deletion: $e');
    }
  }

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Chat'),
          content: const Text(
            'Are you sure you want to delete this chat permanently?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await _deleteChat();
                Navigator.of(context).pop();
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) {
      return '';
    }
    DateTime dateTime = timestamp.toDate();
    return "${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Future.wait([_profilePictureFuture, _isContactSavedFuture]),

      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingCard();
        }

        if (snapshot.hasError) {
          return _buildErrorCard();
        }

        final String? profileUrl = snapshot.data?[0] as String?;
        final bool isSavedContact = snapshot.data?[1] as bool? ?? false;

        return StreamBuilder<Map<String, dynamic>>(
          stream: _latestMessageStream,
          builder: (context, messageSnapshot) {
            final messageData =
                messageSnapshot.data ??
                {'text': 'No messages yet', 'timestamp': null};
            final String messageText = messageData['text'] ?? 'No messages yet';
            final Timestamp? timestamp = messageData['timestamp'];

            return _buildChatCard(
              context,
              profileUrl: profileUrl,
              isSavedContact: isSavedContact,
              messageText: messageText,
              timestamp: timestamp,
            );
          },
        );
      },
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      height: 80,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade100.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Center(
        child: CircularProgressIndicator.adaptive(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      height: 80,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: const Center(
        child: ListTile(
          leading: Icon(Icons.error_outline, color: Colors.red),
          title: Text(
            'Error loading chat',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      ),
    );
  }

  Widget _buildChatCard(
    BuildContext context, {
    required String? profileUrl,
    required bool isSavedContact,
    required String messageText,
    required Timestamp? timestamp,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade100.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => ChatScreen(
                      chatId: widget.chatId,
                      currentUserEmail: widget.currentUserEmail,
                      otherParticipantEmail: widget.otherParticipant,
                    ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Stack(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.blue.shade100,
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child:
                            profileUrl != null && profileUrl.isNotEmpty
                                ? Image.network(
                                  profileUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (context, error, stackTrace) =>
                                          const Icon(Icons.person, size: 28),
                                )
                                : const Icon(Icons.person, size: 28),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            widget.otherParticipant,
                            style: Theme.of(
                              context,
                            ).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            messageText,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey.shade600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatTimestamp(timestamp),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 16),
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline,
                            color: Colors.red.shade400,
                            size: 20,
                          ),
                          onPressed: _showDeleteConfirmationDialog,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ],
                ),
                if (isSavedContact)
                  Positioned(
                    top: 0,
                    left: 44,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.star_rounded,
                        color: Colors.amber,
                        size: 16,
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
