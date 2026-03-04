import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SuggestionTab extends StatelessWidget {
  const SuggestionTab({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        return ListView(
          children: snapshot.data!.docs
              .where((doc) => doc.id != currentUid)
              .map((doc) {
            return ListTile(
              title: Text(doc['name']),
              trailing: IconButton(
                icon: const Icon(Icons.person_add),
                onPressed: () async {
                  await FirebaseFirestore.instance
                      .collection('friend_requests')
                      .add({
                    'fromUid': currentUid,
                    'toUid': doc.id,
                    'status': 'pending',
                  });
                },
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
