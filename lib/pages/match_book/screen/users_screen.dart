import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  ChatListScreen({super.key});
  final User currentUser = FirebaseAuth.instance.currentUser!;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Chats"), backgroundColor: Colors.teal),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chatRooms')
            .where('members', arrayContains: currentUser.uid)
            .orderBy('lastMessage.timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final chatRooms = snapshot.data!.docs;
          if (chatRooms.isEmpty)
            return const Center(child: Text("No chats yet", style: TextStyle(color: Colors.grey)));

          return ListView.builder(
            itemCount: chatRooms.length,
            itemBuilder: (context, index) {
              final chatRoom = chatRooms[index];
              final data = chatRoom.data() as Map<String, dynamic>;
              final members = List<String>.from(data['members']);
              final peerId = members.firstWhere((id) => id != currentUser.uid);
              final lastMsg = data['lastMessage'] ?? {};
              final lastText = lastMsg['text'] ?? "";
              final lastSender = lastMsg['senderId'] ?? "";
              final lastTimeStamp = lastMsg['timestamp'] != null
                  ? (lastMsg['timestamp'] as Timestamp).toDate()
                  : null;

              // Check unread messages count
              final unreadQuery = FirebaseFirestore.instance
                  .collection('chatRooms')
                  .doc(chatRoom.id)
                  .collection('messages')
                  .where('senderId', isNotEqualTo: currentUser.uid)
                  .where('isRead', isEqualTo: false);

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(peerId).get(),
                builder: (context, userSnap) {
                  if (!userSnap.hasData) return const SizedBox();
                  final userData = userSnap.data!.data() as Map<String, dynamic>;
                  final peerName = userData['name'] ?? 'User';
                  final peerAvatar = userData['profilePicture'] ?? '';

                  return StreamBuilder<QuerySnapshot>(
                    stream: unreadQuery.snapshots(),
                    builder: (context, unreadSnap) {
                      final unreadCount = unreadSnap.hasData ? unreadSnap.data!.docs.length : 0;
                      return ListTile(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                peerId: peerId,
                                peerName: peerName,
                                peerAvatar: peerAvatar,
                              ),
                            ),
                          );
                        },
                        leading: CircleAvatar(
                          backgroundImage: peerAvatar.isNotEmpty ? NetworkImage(peerAvatar) : null,
                          child: peerAvatar.isEmpty ? Text(peerName[0].toUpperCase()) : null,
                        ),
                        title: Text(peerName),
                        subtitle: Text(lastText, maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: unreadCount > 0
                            ? Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$unreadCount',
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        )
                            : lastTimeStamp != null
                            ? Text(
                          "${lastTimeStamp.hour}:${lastTimeStamp.minute.toString().padLeft(2, '0')}",
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        )
                            : null,
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}