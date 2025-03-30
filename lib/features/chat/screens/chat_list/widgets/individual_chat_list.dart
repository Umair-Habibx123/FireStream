import 'package:chat_app/features/chat/screens/individual_chat/add_chat/addchatScreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'chat_card.dart';

class IndividualChatList extends StatelessWidget {
  final String currentUserEmail;

  const IndividualChatList({super.key, required this.currentUserEmail});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blueAccent.withOpacity(0.05), Colors.white],
        ),
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('chats')
                .where('participants', arrayContains: currentUserEmail)
                .where('chatType', isEqualTo: 'individual')
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator.adaptive(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      color: Colors.red.shade400,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Couldn\'t load chats',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please check your connection and try again',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          var chatDocs =
              snapshot.data?.docs.where((chat) {
                List<dynamic> deletedBy = chat['deletedBy'] ?? [];
                return !deletedBy.contains(currentUserEmail);
              }).toList();

          if (chatDocs == null || chatDocs.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.forum_outlined,
                    color: Colors.blue.shade300,
                    size: 72,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No conversations yet',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Start chatting with someone to see your conversations here',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue.shade400,
                      side: BorderSide(color: Colors.blue.shade200),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddNewChatScreen(),
                        ),
                      );
                    },
                    child: const Text('Start New Chat'),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            physics: const BouncingScrollPhysics(),
            itemCount: chatDocs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              var chat = chatDocs[index];
              var participants = chat['participants'];
              var otherParticipant = participants.firstWhere(
                (email) => email != currentUserEmail,
              );

              return Material(
                elevation: 0,
                borderRadius: BorderRadius.circular(16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade100, width: 1),
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.shade100.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ChatCard(
                      chatId: chat.id,
                      currentUserEmail: currentUserEmail,
                      otherParticipant: otherParticipant,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
