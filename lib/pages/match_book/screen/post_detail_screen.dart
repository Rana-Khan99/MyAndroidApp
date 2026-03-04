// 🔥 Fully Revamped Professional UI/UX for PostDetailScreen
// Notification fully compatible with NotificationScreen

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'profile_visit_screen.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;
  const PostDetailScreen({super.key, required this.postId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  final User currentUser = FirebaseAuth.instance.currentUser!;

  // 🔔 SEND NOTIFICATION (LIKE / COMMENT)
  Future<void> _sendNotification({
    required String toUid,
    required String type,
    required String postId,
    String? commentText,
    String? commentId,
  }) async {
    // ❌ Do not notify yourself
    if (toUid == currentUser.uid) return;

    final userSnap = await FirebaseFirestore.instance
        .collection("users")
        .doc(currentUser.uid)
        .get();

    final userData = userSnap.data();
    if (userData == null) return;

    await FirebaseFirestore.instance.collection("notifications").add({
      "toUid": toUid,
      "fromUid": currentUser.uid,
      "fromName": userData["name"],
      "fromProfile": userData["profilePicture"] ?? "",
      "type": type, // "comment" or "like"
      "postId": postId,
      "comment": commentText ?? "",
      "commentId": commentId ?? "",
      "timestamp": FieldValue.serverTimestamp(),
      "read": false,
    });
  }

  // 💬 ADD COMMENT + NOTIFICATION
  Future<void> _addComment(Map<String, dynamic> postData) async {
    final String text = _commentController.text.trim();
    if (text.isEmpty) return;

    final userSnap = await FirebaseFirestore.instance
        .collection("users")
        .doc(currentUser.uid)
        .get();

    final userData = userSnap.data();
    if (userData == null) return;

    final commentRef = await FirebaseFirestore.instance
        .collection("posts")
        .doc(widget.postId)
        .collection("comments")
        .add({
      "uid": currentUser.uid,
      "name": userData["name"],
      "profilePicture": userData["profilePicture"] ?? "",
      "comment": text,
      "timestamp": FieldValue.serverTimestamp(),
    });

    // 🔔 COMMENT NOTIFICATION
    await _sendNotification(
      toUid: postData["uid"],
      type: "comment",
      postId: widget.postId,
      commentText: text,
      commentId: commentRef.id,
    );

    _commentController.clear();
  }

  // ❤️ LIKE / UNLIKE + NOTIFICATION
  Future<void> _toggleLike(Map<String, dynamic> postData) async {
    final likeRef = FirebaseFirestore.instance
        .collection("posts")
        .doc(widget.postId)
        .collection("likes")
        .doc(currentUser.uid);

    final likeDoc = await likeRef.get();

    if (likeDoc.exists) {
      await likeRef.delete();
    } else {
      await likeRef.set({
        "timestamp": FieldValue.serverTimestamp(),
      });

      // 🔔 LIKE NOTIFICATION
      await _sendNotification(
        toUid: postData["uid"],
        type: "like",
        postId: widget.postId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.teal,
        elevation: 0,
        title: const Text(
          "Post Details",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("posts")
                  .doc(widget.postId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final data =
                snapshot.data!.data() as Map<String, dynamic>;

                return ListView(
                  padding: const EdgeInsets.all(14),
                  children: [
                    Text(
                      data["title"],
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      data["description"] ?? "",
                      style:
                      TextStyle(color: Colors.grey.shade800),
                    ),
                    const SizedBox(height: 15),

                    if (data["institute"] != null &&
                        data["institute"] != "")
                      _infoChip(Icons.school, data["institute"]),
                    if (data["match_hostel"] != null &&
                        data["match_hostel"] != "")
                      _infoChip(Icons.home, data["match_hostel"]),
                    if (data["location"] != null &&
                        data["location"] != "")
                      _infoChip(Icons.location_on, data["location"]),

                    const SizedBox(height: 15),

                    if (data["imageUrl"] != null &&
                        data["imageUrl"] != "")
                      ClipRRect(
                        borderRadius:
                        BorderRadius.circular(16),
                        child: Image.network(
                          data["imageUrl"],
                          fit: BoxFit.cover,
                        ),
                      ),

                    const SizedBox(height: 20),
                    _likeSection(data),

                    const Divider(height: 30),
                    const Text(
                      "Comments",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    _commentList(),
                  ],
                );
              },
            ),
          ),
          _commentInput(),
        ],
      ),
    );
  }

  // UI HELPERS BELOW (UNCHANGED FUNCTIONALITY)

  Widget _infoChip(IconData icon, String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding:
      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.teal),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _likeSection(Map<String, dynamic> data) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("posts")
          .doc(widget.postId)
          .collection("likes")
          .snapshots(),
      builder: (context, snapshot) {
        final likes =
        snapshot.hasData ? snapshot.data!.docs.length : 0;
        final isLiked = snapshot.hasData
            ? snapshot.data!.docs
            .any((doc) => doc.id == currentUser.uid)
            : false;

        return Row(
          children: [
            GestureDetector(
              onTap: () => _toggleLike(data),
              child: AnimatedContainer(
                duration:
                const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isLiked
                      ? Colors.red.shade100
                      : Colors.grey.shade200,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isLiked
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color:
                  isLiked ? Colors.red : Colors.grey,
                  size: 26,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text("$likes Likes",
                style: const TextStyle(fontSize: 16)),
          ],
        );
      },
    );
  }

  Widget _commentList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("posts")
          .doc(widget.postId)
          .collection("comments")
          .orderBy("timestamp", descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }

        if (snapshot.data!.docs.isEmpty) {
          return const Text(
            "No comments yet",
            style: TextStyle(color: Colors.grey),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final c = snapshot.data!.docs[index].data() as Map<String, dynamic>;

            return Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: GestureDetector(
                  onTap: () {
                    // 🔹 Profile picture tap → ProfileVisitScreen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProfileVisitScreen(userId: c["uid"]),
                      ),
                    );
                  },
                  child: CircleAvatar(
                    backgroundImage: c["profilePicture"] != ""
                        ? NetworkImage(c["profilePicture"])
                        : null,
                    child: c["profilePicture"] == ""
                        ? Text(
                      c["name"][0].toString().toUpperCase(),
                    )
                        : null,
                  ),
                ),
                title: GestureDetector(
                  onTap: () {
                    // 🔹 Name tap → ProfileVisitScreen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProfileVisitScreen(userId: c["uid"]),
                      ),
                    );
                  },
                  child: Text(
                    c["name"],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                subtitle: Text(c["comment"]),
              ),
            );
          },
        );
      },
    );
  }


  Widget _commentInput() {
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, -2)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: "Write a comment...",
                filled: true,
                fillColor: Colors.grey.shade200,
                border: OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: Colors.teal,
            child: IconButton(
              icon: const Icon(Icons.send,
                  color: Colors.white),
              onPressed: () async {
                final postSnap =
                await FirebaseFirestore.instance
                    .collection("posts")
                    .doc(widget.postId)
                    .get();

                _addComment(
                    postSnap.data() as Map<String, dynamic>);
              },
            ),
          ),
        ],
      ),
    );
  }
}
