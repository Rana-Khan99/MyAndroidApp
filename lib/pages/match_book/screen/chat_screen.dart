import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'profile_visit_screen.dart';

class ChatScreen extends StatefulWidget {
  final String peerId;
  final String peerName;
  final String peerAvatar;

  const ChatScreen({
    super.key,
    required this.peerId,
    required this.peerName,
    this.peerAvatar = '',
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final User currentUser = FirebaseAuth.instance.currentUser!;
  bool isTyping = false;
  Timer? _typingTimer;
  bool isChatReady = false;

  String get chatId {
    final ids = [currentUser.uid, widget.peerId]..sort();
    return ids.join('_');
  }

  @override
  void initState() {
    super.initState();
    _controller.addListener(_typingListener);
    _initChat();
    _markMessagesAsRead();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  void _typingListener() {
    if (!isChatReady) return;
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(milliseconds: 300), () {
      final typingNow = _controller.text.trim().isNotEmpty;
      if (typingNow != isTyping) {
        isTyping = typingNow;
        _updateTypingStatus(typingNow);
      }
    });
  }

  Future<void> _initChat() async {
    final chatRef = FirebaseFirestore.instance.collection('chatRooms').doc(chatId);
    final snap = await chatRef.get();
    if (!snap.exists) {
      await chatRef.set({
        'members': [currentUser.uid, widget.peerId],
        'typing': {currentUser.uid: false, widget.peerId: false},
        'lastMessage': {},
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    setState(() => isChatReady = true);
  }

  Future<void> _updateTypingStatus(bool typing) async {
    final chatRef = FirebaseFirestore.instance.collection('chatRooms').doc(chatId);
    await chatRef.set({'typing.${currentUser.uid}': typing}, SetOptions(merge: true));
  }

  Future<void> sendMessage() async {
    // Prevent sending message to self
    if (currentUser.uid == widget.peerId) {
      _showCannotMessageSelfDialog();
      return;
    }

    if (_controller.text.trim().isEmpty) return;

    final text = _controller.text.trim();
    _controller.clear();
    _updateTypingStatus(false);

    final chatRef = FirebaseFirestore.instance.collection('chatRooms').doc(chatId);
    final messageRef = chatRef.collection('messages').doc();

    final messageData = {
      'text': text,
      'senderId': currentUser.uid,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    };

    try {
      // Update lastMessage & create chatRoom if first
      await chatRef.set({
        'members': [currentUser.uid, widget.peerId],
        'lastMessage': {
          'text': text,
          'senderId': currentUser.uid,
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
        },
      }, SetOptions(merge: true));

      // Add message
      await messageRef.set(messageData);

      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } catch (e) {
      debugPrint("Send message error: $e");
    }
  }

  Future<void> _markMessagesAsRead() async {
    final messagesQuery = await FirebaseFirestore.instance
        .collection('chatRooms')
        .doc(chatId)
        .collection('messages')
        .where('senderId', isNotEqualTo: currentUser.uid)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = FirebaseFirestore.instance.batch();
    for (var msg in messagesQuery.docs) {
      batch.update(msg.reference, {'isRead': true});
    }
    await batch.commit();
  }

  void _openProfile() {
    if (currentUser.uid == widget.peerId) return;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProfileVisitScreen(userId: widget.peerId)),
    );
  }

  void _showCannotMessageSelfDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Action not allowed"),
        content: const Text("You cannot message yourself."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(DocumentSnapshot msgDoc, Map<String, dynamic> data) {
    final isMe = data['senderId'] == currentUser.uid;
    final timestamp = data['timestamp'] != null ? (data['timestamp'] as Timestamp).toDate() : null;
    final isRead = data['isRead'] ?? false;

    String timeString = '';
    if (timestamp != null) {
      final hour = timestamp.hour;
      final minute = timestamp.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final formattedHour = hour % 12 == 0 ? 12 : hour % 12;
      timeString = '$formattedHour:$minute $period';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe)
            CircleAvatar(
              radius: 16,
              backgroundImage: widget.peerAvatar.isNotEmpty ? NetworkImage(widget.peerAvatar) : null,
              child: widget.peerAvatar.isEmpty ? Text(widget.peerName[0].toUpperCase()) : null,
            ),
          if (!isMe) const SizedBox(width: 6),
          Flexible(
            child: Container(
              decoration: BoxDecoration(
                color: isMe ? Colors.teal : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    data['text'] ?? '',
                    style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (timeString.isNotEmpty)
                        Text(
                          timeString,
                          style: TextStyle(fontSize: 11, color: isMe ? Colors.white70 : Colors.black54),
                        ),
                      const SizedBox(width: 4),
                      if (isMe)
                        Icon(
                          isRead ? Icons.done_all : Icons.check,
                          size: 16,
                          color: isRead ? Colors.blue : Colors.white70,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: GestureDetector(
          onTap: _openProfile,
          child: Row(
            children: [
              CircleAvatar(
                backgroundImage: widget.peerAvatar.isNotEmpty ? NetworkImage(widget.peerAvatar) : null,
                child: widget.peerAvatar.isEmpty ? Text(widget.peerName[0].toUpperCase()) : null,
              ),
              const SizedBox(width: 8),
              Text(widget.peerName, style: const TextStyle(fontSize: 18)),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chatRooms')
                  .doc(chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final messages = snapshot.data!.docs;
                return ListView.builder(
                  reverse: true,
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msgDoc = messages[index];
                    final data = msgDoc.data() as Map<String, dynamic>;
                    return _buildMessage(msgDoc, data);
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(color: Colors.teal, shape: BoxShape.circle),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}