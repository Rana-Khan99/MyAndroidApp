import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_screen.dart';
import 'post_detail_screen.dart';

class ProfileVisitScreen extends StatefulWidget {
  final String userId;
  const ProfileVisitScreen({super.key, required this.userId});

  @override
  State<ProfileVisitScreen> createState() => _ProfileVisitScreenState();
}

class _ProfileVisitScreenState extends State<ProfileVisitScreen> {
  Map<String, dynamic>? _userData;
  bool _loading = true;
  final currentUser = FirebaseAuth.instance.currentUser!;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final doc = await FirebaseFirestore.instance.collection("users").doc(widget.userId).get();
      if (doc.exists) _userData = doc.data();
    } catch (e) {
      print("Error loading user data: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  Widget _infoRow(String label, String? value, {bool copyable = false}) {
    if (value == null || value.isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            "$label: ",
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          Expanded(
            child: copyable
                ? SelectableText(
              value,
              style: const TextStyle(fontSize: 15, color: Colors.black87),
            )
                : Text(
              value,
              style: const TextStyle(fontSize: 15, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  void _openChatScreen() {
    if (_userData == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          peerId: widget.userId,
          peerName: _userData?['name'] ?? 'User',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4f7f9),
      appBar: AppBar(
        title: Text(_userData?['name'] ?? 'Profile'),
        backgroundColor: Colors.teal,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(color: Colors.grey.shade300),
                  child: _userData?['coverPhoto'] != null
                      ? Image.network(_userData!['coverPhoto'], fit: BoxFit.cover)
                      : null,
                ),
                Positioned(
                  bottom: -40,
                  left: 20,
                  child: CircleAvatar(
                    radius: 55,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: _userData?['profilePicture'] != null
                          ? NetworkImage(_userData!['profilePicture'])
                          : null,
                      child: _userData?['profilePicture'] == null
                          ? Text(
                        _userData?['name'] != null
                            ? _userData!['name'][0].toUpperCase()
                            : 'U',
                        style: const TextStyle(fontSize: 35, fontWeight: FontWeight.bold),
                      )
                          : null,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 50),

            // Profile Info Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    spreadRadius: 2,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_userData?['name'] ?? '',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text(_userData?['institute'] ?? '',
                      style: const TextStyle(fontSize: 15, color: Colors.grey)),
                  const SizedBox(height: 14),

                  Center(
                    child: ElevatedButton.icon(
                      onPressed: _openChatScreen,
                      icon: const Icon(Icons.message, size: 20),
                      label: const Text('Message'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        elevation: 3,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Details section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    spreadRadius: 2,
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Profile Details',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal)),
                  const SizedBox(height: 12),

                  _infoRow('Work', _userData?['work']),
                  _infoRow('Institute/College/Office', _userData?['institute']),
                  _infoRow('Hostel/Home', _userData?['match_hostel']),
                  _infoRow('Phone', _userData?['phone'], copyable: true),
                  _infoRow('Address', _userData?['address']),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Posts section
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text('All Posts',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal)),
                ],
              ),
            ),

            const SizedBox(height: 10),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .where('uid', isEqualTo: widget.userId)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                if (snap.data!.docs.isEmpty) return const Padding(padding: EdgeInsets.all(16), child: Text('No posts yet.'));

                return ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: snap.data!.docs.length,
                  itemBuilder: (context, index) {
                    final pDoc = snap.data!.docs[index];
                    final p = pDoc.data() as Map<String, dynamic>;
                    final postId = pDoc.id;

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                            context, MaterialPageRoute(builder: (_) => PostDetailScreen(postId: postId)));
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 2)],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (p['imageUrl'] != null && p['imageUrl'] != '')
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Image.network(p['imageUrl'], height: 200, width: double.infinity, fit: BoxFit.cover),
                                ),

                              const SizedBox(height: 10),

                              Text(p['title'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

                              const SizedBox(height: 5),

                              Text(p['description'] ?? '', style: const TextStyle(fontSize: 15)),

                              const SizedBox(height: 6),

                              if (p['location'] != null && p['location'] != '')
                                Row(
                                  children: [
                                    const Icon(Icons.place, size: 16, color: Colors.teal),
                                    const SizedBox(width: 4),
                                    Text(p['location'], style: const TextStyle(color: Colors.grey)),
                                  ],
                                ),

                              if (p['institute'] != null && p['institute'] != '')
                                Text('🎓 ${p['institute']}', style: const TextStyle(color: Colors.grey)),

                              if (p['match_hostel'] != null && p['match_hostel'] != '')
                                Text('🏠 ${p['match_hostel']}', style: const TextStyle(color: Colors.grey)),

                              const SizedBox(height: 10),

                              Row(
                                children: [
                                  StreamBuilder<QuerySnapshot>(
                                    stream: FirebaseFirestore.instance
                                        .collection('posts')
                                        .doc(postId)
                                        .collection('likes')
                                        .snapshots(),
                                    builder: (context, likeSnap) {
                                      final likeCount = likeSnap.hasData ? likeSnap.data!.docs.length : 0;
                                      return Text('❤️ $likeCount   ');
                                    },
                                  ),
                                  StreamBuilder<QuerySnapshot>(
                                    stream: FirebaseFirestore.instance
                                        .collection('posts')
                                        .doc(postId)
                                        .collection('comments')
                                        .snapshots(),
                                    builder: (context, commentSnap) {
                                      final commentCount = commentSnap.hasData ? commentSnap.data!.docs.length : 0;
                                      return Text('💬 $commentCount');
                                    },
                                  ),
                                ],
                              ),

                              const SizedBox(height: 6),

                              Text(
                                p['timestamp'] != null ? (p['timestamp'] as Timestamp).toDate().toString() : '',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}