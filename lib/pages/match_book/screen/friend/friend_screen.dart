import 'package:flutter/material.dart';
import '../friend/friendlist.dart';
import 'requestfrien.dart';
import 'suggesfriend.dart';

class FriendScreen extends StatelessWidget {
  const FriendScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Friends"),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Requests"),
              Tab(text: "Friends"),
              Tab(text: "Suggestions"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            RequestTab(),
            FriendListTab(),
            SuggestionTab(),
          ],
        ),
      ),
    );
  }
}
