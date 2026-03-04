import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'profile_screen.dart';
import 'AddPostScreen.dart';
import 'profile_visit_screen.dart';
import 'post_detail_screen.dart';
import 'notification_screen.dart';

class HomeFeedScreen extends StatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  State<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends State<HomeFeedScreen> {
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = "";
  final ScrollController _scrollController = ScrollController();
  Key _feedKey = UniqueKey();


  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot> _postsStream() {
    final posts = FirebaseFirestore.instance.collection("posts");
    if (searchQuery.isEmpty) {
      return posts.orderBy("timestamp", descending: true).snapshots();
    }
    return posts
        .where("searchKeywords", arrayContains: searchQuery)
        .snapshots();
  }
  /// HOME CLICK ACTION
  void _onHomeTap() {
    _searchController.clear();

    setState(() {
      searchQuery = "";
      _feedKey = UniqueKey(); // StreamBuilder reload
    });

    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }


  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      // ---------------- APP BAR ----------------
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        titleSpacing: 16,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF00897B), Color(0xFF4DB6AC)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(28),
            ),
          ),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(28),
          ),
        ),

        // 🔥 ONE LINE: TITLE + SEARCH
        title: Row(
          children: [
            // 🏠 HOME (Safe Click)
            InkWell(
              onTap: _onHomeTap,
              child: const Text(
                "Home",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),


            const SizedBox(width: 12),

            // 🔍 SEARCH
            Expanded(
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: "Search posts, users...",
                    hintStyle: TextStyle(color: Colors.grey.shade600),
                    prefixIcon:
                    const Icon(Icons.search, color: Colors.teal),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => searchQuery = "");
                      },
                    )
                        : null,
                    border: InputBorder.none,
                    contentPadding:
                    const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ),
          ],
        ),

      ),

      // ➕ Add Post
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal.shade600,
        child: const Icon(Icons.add, size: 28),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddPostScreen()),
          );
        },
      ),

      // ---------------- FEED ----------------
      body: StreamBuilder<QuerySnapshot>(
        key: _feedKey, // reload trigger
        stream: _postsStream(),
        builder: (context, snap) {

          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }


          if (snap.data!.docs.isEmpty) {
            return const Center(child: Text("No posts found"));
          }

          return ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(12),
            itemCount: snap.data!.docs.length,
            itemBuilder: (context, index) {
              final postDoc = snap.data!.docs[index];
              final data = postDoc.data() as Map<String, dynamic>;
              final postId = postDoc.id;
              final userId = data["uid"];

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection("users")
                    .doc(userId)
                    .get(),
                builder: (context, userSnap) {
                  if (!userSnap.hasData) return const SizedBox();

                  final userData =
                  userSnap.data!.data() as Map<String, dynamic>?;

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              PostDetailScreen(postId: postId),
                        ),
                      );
                    },
                    child: Card(
                      margin: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 4),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ---------- USER INFO ----------
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ProfileVisitScreen(userId: userId),
                                  ),
                                );
                              },
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundImage:
                                    userData?["profilePicture"] != null
                                        ? NetworkImage(
                                        userData!["profilePicture"])
                                        : null,
                                    child: userData?["profilePicture"] == null
                                        ? Text(
                                      userData?["name"]?[0]
                                          .toUpperCase() ??
                                          "U",
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                    )
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        userData?["name"] ?? "User",
                                        style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        data["timestamp"] != null
                                            ? (data["timestamp"] as Timestamp)
                                            .toDate()
                                            .toString()
                                            : "",
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),

                            const SizedBox(height: 12),

                            // ---------- POST TEXT ----------
                            Text(
                              data["title"] ?? "",
                              style: const TextStyle(
                                  fontSize: 19, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              data["description"] ?? "",
                              style: TextStyle(
                                  fontSize: 15, color: Colors.grey.shade800),
                            ),

                            const SizedBox(height: 10),

                            // ---------- IMAGE ----------
                            if (data["imageUrl"] != null &&
                                data["imageUrl"] != "")
                              ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: Image.network(
                                  data["imageUrl"],
                                  height: 220,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),

                            const SizedBox(height: 10),

                            // ---------- EXTRA INFO ----------


                            if (data["institute"] != null &&
                                data["institute"].toString().isNotEmpty)
                              Text("🎓 ${data["institute"]}",
                                  style: TextStyle(
                                      color: Colors.grey.shade700)),

                            if (data["match_hostel"] != null &&
                                data["match_hostel"].toString().isNotEmpty)
                              Text("🏠 ${data["match_hostel"]}",
                                  style: TextStyle(
                                      color: Colors.grey.shade700)),

                            if (data["location"] != null &&
                                data["location"].toString().isNotEmpty)
                              Row(
                                children: [
                                  const Icon(Icons.location_on,
                                      size: 16, color: Colors.teal),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      data["location"],
                                      style: TextStyle(
                                          color: Colors.grey.shade700),
                                    ),
                                  ),
                                ],
                              ),

                            if (data["work"] != null &&
                                data["work"].toString().isNotEmpty)
                              Text("💼 ${data["work"]}",
                                  style: TextStyle(
                                      color: Colors.grey.shade700)),

                            const SizedBox(height: 12),

                            // ---------- LIKE & COMMENT ----------
                            Row(
                              children: [
                                // ❤️ LIKE + COUNT + Notification
                                StreamBuilder<QuerySnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection("posts")
                                      .doc(postId)
                                      .collection("likes")
                                      .snapshots(),
                                  builder: (context, likeSnap) {
                                    final likes = likeSnap.data?.docs ?? [];
                                    final isLiked =
                                    likes.any((d) => d.id == currentUid);

                                    return Row(
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            isLiked
                                                ? Icons.favorite
                                                : Icons.favorite_border,
                                            color: isLiked
                                                ? Colors.red
                                                : Colors.grey.shade600,
                                          ),
                                          onPressed: () async {
                                            final likeRef = FirebaseFirestore
                                                .instance
                                                .collection("posts")
                                                .doc(postId)
                                                .collection("likes")
                                                .doc(currentUid);

                                            if (isLiked) {
                                              await likeRef.delete();
                                            } else {
                                              await likeRef
                                                  .set({"timestamp": DateTime.now()});

                                              // 🔔 Notification for Like
                                              if (data["uid"] != currentUid) {
                                                final userDoc = await FirebaseFirestore
                                                    .instance
                                                    .collection("users")
                                                    .doc(currentUid)
                                                    .get();
                                                final uData = userDoc.data()!;
                                                await FirebaseFirestore.instance
                                                    .collection("notifications")
                                                    .add({
                                                  "toUid": data["uid"],
                                                  "fromUid": currentUid,
                                                  "fromName": uData["name"],
                                                  "fromProfile":
                                                  uData["profilePicture"] ?? "",
                                                  "type": "like",
                                                  "postId": postId,
                                                  "timestamp": FieldValue.serverTimestamp(),
                                                  "read": false,
                                                });
                                              }
                                            }
                                          },
                                        ),
                                        Text(
                                          likes.length.toString(),
                                          style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey.shade700),
                                        ),
                                      ],
                                    );
                                  },
                                ),

                                const SizedBox(width: 16),

                                // 💬 COMMENT COUNT
                                StreamBuilder<QuerySnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection("posts")
                                      .doc(postId)
                                      .collection("comments")
                                      .snapshots(),
                                  builder: (context, commentSnap) {
                                    final count =
                                        commentSnap.data?.docs.length ?? 0;
                                    return Text(
                                      "Comments ($count)",
                                      style:
                                      TextStyle(color: Colors.grey.shade700),
                                    );
                                  },
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
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
