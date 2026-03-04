import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RequestTab extends StatelessWidget {
  const RequestTab({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('friend_requests')
          .where('toUid', isEqualTo: uid)
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        return ListView(
          children: snapshot.data!.docs.map((doc) {
            return ListTile(
              title: Text("Request from ${doc['fromUid']}"),
              trailing: ElevatedButton(
                child: const Text("Accept"),
                onPressed: () async {
                  await FirebaseFirestore.instance
                      .collection('friends')
                      .add({
                    'user1': uid,
                    'user2': doc['fromUid'],
                  });

                  await doc.reference.update({'status': 'accepted'});
                },
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
