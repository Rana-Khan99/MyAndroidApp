// ------------------------ match_book_screen.dart ------------------------
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screen/home_feed_screen.dart';
import 'screen/users_screen.dart';
import 'screen/notification_screen.dart';
import 'screen/profile_screen.dart';
import 'screen/users_screen.dart';

class MatchBookScreen extends StatefulWidget {
  const MatchBookScreen({super.key});
  @override
  State<MatchBookScreen> createState() => _MatchBookScreenState();
}

class _MatchBookScreenState extends State<MatchBookScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final currentUser = FirebaseAuth.instance.currentUser!;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      const Tab(icon: Icon(Icons.home), text: "Home"),

      // ---------------- Chat Tab with Badge ----------------
      Tab(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection("chatRooms")
              .where("members", arrayContains: currentUser.uid)
              .snapshots(),
          builder: (context, snap) {
            int unreadCount = 0;
            if (snap.hasData) {
              for (var doc in snap.data!.docs) {
                final lastMsg = doc['lastMessage'];
                if (lastMsg != null &&
                    lastMsg['senderId'] != currentUser.uid &&
                    !(lastMsg['isRead'] ?? true)) {
                  unreadCount += 1;
                }
              }
            }

            return Stack(
              clipBehavior: Clip.none,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.chat),
                    SizedBox(height: 4),
                    Text("Chats", style: TextStyle(fontSize: 12)),
                  ],
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      child: Center(
                        child: Text(
                          unreadCount > 9 ? "9+" : unreadCount.toString(),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),

      // ---------------- Notifications ----------------
      Tab(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection("notifications")
              .where("toUid", isEqualTo: currentUser.uid)
              .where("read", isEqualTo: false)
              .snapshots(),
          builder: (context, snap) {
            final unread = snap.hasData ? snap.data!.docs.length : 0;

            return Stack(
              clipBehavior: Clip.none,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.notifications),
                    SizedBox(height: 4),
                    Text("Alerts", style: TextStyle(fontSize: 12)),
                  ],
                ),
                if (unread > 0)
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      child: Center(
                        child: Text(
                          unread > 9 ? "9+" : unread.toString(),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),

      const Tab(icon: Icon(Icons.person), text: "Profile"),
    ];

    final tabViews = [
      HomeFeedScreen(),
      ChatListScreen(),
      NotificationScreen(),
      ProfileScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Hostel Find"),
        backgroundColor: Colors.teal,
        bottom: TabBar(controller: _tabController, tabs: tabs, isScrollable: true),
      ),
      body: TabBarView(controller: _tabController, children: tabViews),
    );
  }
}