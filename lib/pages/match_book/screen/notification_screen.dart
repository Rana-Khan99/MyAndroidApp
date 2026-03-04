import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'post_detail_screen.dart';
import 'profile_visit_screen.dart';

class NotificationScreen extends StatelessWidget {
  NotificationScreen({super.key});

  final User currentUser = FirebaseAuth.instance.currentUser!;

  // Delete a single notification
  Future<void> deleteNotification(String docId) async {
    await FirebaseFirestore.instance.collection("notifications").doc(docId).delete();
  }

  // Delete all notifications
  Future<void> deleteAllNotifications() async {
    final snapshot = await FirebaseFirestore.instance
        .collection("notifications")
        .where("toUid", isEqualTo: currentUser.uid)
        .get();

    final batch = FirebaseFirestore.instance.batch();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  String formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    return DateFormat('MMM d, yyyy – h:mm a').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          backgroundColor: Colors.teal,
          elevation: 1,
          title: const Text(
            "Notifications",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: "Delete All",
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Delete all notifications?"),
                    content: const Text(
                        "This action cannot be undone. Are you sure?"),
                    actions: [
                      TextButton(
                        child: const Text("Cancel"),
                        onPressed: () => Navigator.pop(context, false),
                      ),
                      TextButton(
                        child: const Text("Delete"),
                        onPressed: () => Navigator.pop(context, true),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await deleteAllNotifications();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("All notifications deleted")),
                  );
                }
              },
            ),
          ],
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection("notifications")
              .where("toUid", isEqualTo: currentUser.uid)
              .orderBy("timestamp", descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.teal),
              );
            }

            if (snapshot.data!.docs.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(24),
                        child: Icon(
                          Icons.notifications_off,
                          size: screenWidth * 0.15, // responsive size
                          color: Colors.teal.shade300,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      const Text(
                        "No notifications yet!",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.01),
                      const Text(
                        "New activity will appear here.",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final doc = snapshot.data!.docs[index];
                final data = doc.data() as Map<String, dynamic>;
                final isUnread = data["read"] == false;
                final isComment = data["type"] == "comment";

                return Dismissible(
                  key: Key(doc.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: Colors.red.shade400,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (direction) async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Delete notification?"),
                        content: const Text(
                            "This notification will be permanently deleted."),
                        actions: [
                          TextButton(
                            child: const Text("Cancel"),
                            onPressed: () => Navigator.pop(context, false),
                          ),
                          TextButton(
                            child: const Text("Delete"),
                            onPressed: () => Navigator.pop(context, true),
                          ),
                        ],
                      ),
                    );
                    return confirm == true;
                  },
                  onDismissed: (direction) async {
                    await deleteNotification(doc.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Notification deleted")),
                    );
                  },
                  child: Card(
                    elevation: isUnread ? 3 : 1,
                    color: isUnread ? Colors.teal.shade50 : Colors.white,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      leading: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProfileVisitScreen(
                                userId: data["fromUid"],
                              ),
                            ),
                          );
                        },
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: screenWidth * 0.06, // responsive
                              backgroundColor: Colors.teal.shade200,
                              backgroundImage: (data["fromProfile"] != null && data["fromProfile"] != "")
                                  ? NetworkImage(data["fromProfile"])
                                  : null,
                              child: (data["fromProfile"] == null || data["fromProfile"] == "")
                                  ? Text(
                                data["fromName"][0].toUpperCase(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: screenWidth * 0.05,
                                ),
                              )
                                  : null,
                            ),
                            if (isUnread)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  width: screenWidth * 0.025,
                                  height: screenWidth * 0.025,
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              data["fromName"],
                              style: TextStyle(
                                fontWeight: isUnread ? FontWeight.bold : FontWeight.w500,
                                fontSize: screenWidth * 0.045,
                              ),
                            ),
                          ),
                          if (isUnread)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                "NEW",
                                style: TextStyle(color: Colors.white, fontSize: 10),
                              ),
                            ),
                        ],
                      ),
                      subtitle: Text(
                        isComment
                            ? "Commented: ${data["comment"]}"
                            : "Liked your post",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey.shade700, fontSize: screenWidth * 0.035),
                      ),
                      trailing: data["timestamp"] != null
                          ? Text(
                        formatTimestamp(data["timestamp"]),
                        style: TextStyle(fontSize: screenWidth * 0.03, color: Colors.grey),
                      )
                          : null,
                      onTap: () async {
                        if (isUnread) {
                          await doc.reference.update({"read": true});
                        }

                        if (data["postId"] != null && data["postId"].toString().isNotEmpty) {
                          final postSnapshot = await FirebaseFirestore.instance
                              .collection("posts")
                              .doc(data["postId"])
                              .get();

                          if (postSnapshot.exists) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PostDetailScreen(postId: data["postId"]),
                              ),
                            );
                          } else {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text("Post Deleted"),
                                content: const Text(
                                    "This post has been deleted. Notification not available."),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text("OK"),
                                  ),
                                ],
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
