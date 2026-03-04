import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'AddPostScreen.dart';
import 'post_detail_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final currentUser = FirebaseAuth.instance.currentUser!;
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _instituteController = TextEditingController();
  final _matchController = TextEditingController();
  final _workController = TextEditingController();

  File? _pickedProfileImage;
  File? _pickedCoverImage;
  final picker = ImagePicker();

  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  bool _isUploadingProfile = false;
  bool _isUploadingCover = false;

  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
    if (doc.exists) {
      _userData = doc.data();
      _nameController.text = _userData?['name'] ?? '';
      _phoneController.text = _userData?['phone'] ?? '';
      _instituteController.text = _userData?['institute'] ?? '';
      _matchController.text = _userData?['match_hostel'] ?? '';
      _addressController.text = _userData?['address'] ?? '';
      _workController.text = _userData?['work'] ?? '';
    }
    setState(() => _isLoading = false);
  }

  /// 🔹 Upload image to Supabase Storage
  Future<String?> _uploadToSupabase(File file, String folder) async {
    try {
      final fileName = "${currentUser.uid}.jpg";
      final path = "$folder/$fileName";

      await supabase.storage.from('profile_photo').upload(
        path,
        file,
        fileOptions: const FileOptions(
          upsert: true,
          cacheControl: '3600',
        ),
      );

      final publicUrl =
      supabase.storage.from('profile_photo').getPublicUrl(path);

      return publicUrl;
    } catch (e) {
      debugPrint("Upload Error: $e");
      return null;
    }
  }

  /// 🔹 Pick & Upload Profile Image
  Future<void> _pickProfileImage() async {
    final pickedFile =
    await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);

    if (pickedFile == null) return;

    final file = File(pickedFile.path);

    setState(() {
      _pickedProfileImage = file;
      _isUploadingProfile = true;
    });

    final url = await _uploadToSupabase(file, "profile");

    if (url != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .update({'profilePicture': url});

      setState(() {
        _userData?['profilePicture'] = url;
      });
    }

    setState(() {
      _isUploadingProfile = false;
    });
  }

  /// 🔹 Pick & Upload Cover Image
  Future<void> _pickCoverImage() async {
    final pickedFile =
    await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);

    if (pickedFile == null) return;

    final file = File(pickedFile.path);

    // ➤ Step 1: আগেই UI-তে দেখানো
    setState(() {
      _pickedCoverImage = file;
      _isUploadingCover = true;
    });

    // ➤ Step 2: Upload to Supabase
    final url = await _uploadToSupabase(file, "cover");

    if (url != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .update({
        'coverPhoto': url,
        'profilePicture': url, // Auto profile picture
      });

      setState(() {
        _userData?['coverPhoto'] = url;
        _userData?['profilePicture'] = url;
      });
    }

    setState(() => _isUploadingCover = false); // Upload done
  }
  Future<void> _saveProfile() async {
    await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).set({
      'name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'institute': _instituteController.text.trim(),
      'match_hostel': _matchController.text.trim(),
      'address': _addressController.text.trim(),
      'work': _workController.text.trim(),
    }, SetOptions(merge: true));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile Updated Successfully!')),
    );

    _loadUserData();
  }

  /// 🔹 Proper post delete: Firestore + likes/comments
  Future<void> _deletePost(String postId) async {
    final postRef = FirebaseFirestore.instance.collection("posts").doc(postId);
    final postSnap = await postRef.get();

    if (!postSnap.exists) return;

    final postData = postSnap.data() as Map<String, dynamic>;

    // Delete likes
    final likesSnap = await postRef.collection("likes").get();
    for (var doc in likesSnap.docs) {
      await doc.reference.delete();
    }

    // Delete comments
    final commentsSnap = await postRef.collection("comments").get();
    for (var doc in commentsSnap.docs) {
      await doc.reference.delete();
    }

    // Delete post doc
    await postRef.delete();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Post deleted permanently")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = currentUser.uid;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, size: 28),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AddPostScreen()));
        },
      ),
      appBar: AppBar(
        title: const Text(
          "My Profile",
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        backgroundColor: Colors.teal,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover & Profile Images
// Cover & Profile Images
            Stack(
              children: [
                // Cover Photo
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    image: _pickedCoverImage != null
                        ? DecorationImage(
                      image: FileImage(_pickedCoverImage!),
                      fit: BoxFit.cover,
                    )
                        : _userData?['coverPhoto'] != null
                        ? DecorationImage(
                      image: NetworkImage(_userData!['coverPhoto']),
                      fit: BoxFit.cover,
                    )
                        : null,
                  ),
                  child: (_pickedCoverImage == null && _userData?['coverPhoto'] == null)
                      ? const Center(
                    child: Text(
                      "Add Cover Photo",
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                  )
                      : null,
                ),

// Loader overlay when uploading cover photo
                if (_isUploadingCover)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black38,
                      child: const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    ),
                  ),
                if (_isUploadingCover)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black38,
                      child: const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    ),
                  ),
                Positioned(
                  right: 15,
                  bottom: 15,
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.black54,
                    child: IconButton(
                      icon: const Icon(Icons.camera_alt, color: Colors.white),
                      onPressed: _pickCoverImage,
                    ),
                  ),
                ),

                // Profile Photo
                Positioned(
                  bottom: -45,
                  left: MediaQuery.of(context).size.width / 2 - 52,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 52,
                        backgroundImage: _pickedProfileImage != null
                            ? FileImage(_pickedProfileImage!)
                            : _userData?["profilePicture"] != null
                            ? NetworkImage(_userData!["profilePicture"]) as ImageProvider
                            : null,
                        backgroundColor: Colors.grey.shade300,
                        child: (_pickedProfileImage == null && _userData?["profilePicture"] == null)
                            ? Text(
                          _userData?['name'] != null && _userData!['name'].isNotEmpty
                              ? _userData!['name'][0].toUpperCase()
                              : "U",
                          style: const TextStyle(fontSize: 40, color: Colors.teal),
                        )
                            : null,
                      ),

                      // Camera Icon on Profile Picture
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.teal,
                          child: IconButton(
                            icon: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                            onPressed: _pickProfileImage,
                          ),
                        ),
                      ),

                      if (_isUploadingProfile)
                        Positioned.fill(
                          child: Container(
                            color: Colors.black38,
                            child: const Center(
                              child: CircularProgressIndicator(color: Colors.white),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 70),

            // Profile Form
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                elevation: 5,
                shadowColor: Colors.grey.shade300,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _field(_nameController, 'Full Name', Icons.person),
                      _readonlyField(currentUser.email ?? "No Email", 'Email'),
                      _field(_phoneController, 'Phone', Icons.phone),
                      _field(_instituteController, 'Institute/College/Office', Icons.school),
                      _field(_matchController, 'Hostel/Home', Icons.house),
                      _field(_workController, 'Work', Icons.work),
                      _field(_addressController, 'Address', Icons.location_on),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          elevation: 3,
                          shadowColor: Colors.teal.shade200,
                        ),
                        child: const Text(
                          'Save Profile',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 25),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "Your Posts",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.teal),
              ),
            ),
            const SizedBox(height: 10),

            // POSTS LIST WITH DELETE
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("posts")
                  .where("uid", isEqualTo: uid)
                  .orderBy("timestamp", descending: true)
                  .snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                if (snap.data!.docs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: Text("No posts yet", style: TextStyle(fontSize: 16))),
                  );
                }

                return ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: snap.data!.docs.length,
                  itemBuilder: (context, index) {
                    final pDoc = snap.data!.docs[index];
                    final p = pDoc.data() as Map<String, dynamic>;
                    final postId = pDoc.id;

                    return Dismissible(
                      key: Key(postId),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: Colors.red.shade400,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (direction) async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text("Delete Post?"),
                            content: const Text("This post will be permanently deleted."),
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
                        await _deletePost(postId);
                      },
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (_) => PostDetailScreen(postId: postId),
                          ));
                        },
                        child: Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (p["imageUrl"] != null && p["imageUrl"] != "")
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.network(
                                      p["imageUrl"],
                                      height: 200,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                const SizedBox(height: 12),
                                Text(
                                  p["title"] ?? "",
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 6),
                                Text(p["description"] ?? "", style: const TextStyle(fontSize: 15)),
                                const SizedBox(height: 8),
                                if (p["institute"] != null && p["institute"].isNotEmpty)
                                  Text("🎓 ${p["institute"]}", style: TextStyle(color: Colors.grey.shade700)),
                                if (p["match_hostel"] != null && p["match_hostel"].isNotEmpty)
                                  Text("🏠 ${p["match_hostel"]}", style: TextStyle(color: Colors.grey.shade700)),
                                if (p["work"] != null && p["work"].isNotEmpty)
                                  Text("💼 ${p["work"]}", style: TextStyle(color: Colors.grey.shade700)),
                                if (p["location"] != null && p["location"].isNotEmpty)
                                  Row(
                                    children: [
                                      Icon(Icons.location_on, size: 16, color: Colors.teal),
                                      const SizedBox(width: 4),
                                      Text(p["location"], style: TextStyle(color: Colors.grey.shade700)),
                                    ],
                                  ),
                                const SizedBox(height: 8),
                                Text(
                                  p["timestamp"] != null
                                      ? (p["timestamp"] as Timestamp).toDate().toString()
                                      : "",
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    StreamBuilder<QuerySnapshot>(
                                      stream: FirebaseFirestore.instance
                                          .collection("posts")
                                          .doc(postId)
                                          .collection("likes")
                                          .snapshots(),
                                      builder: (context, likeSnap) {
                                        final likeCount = likeSnap.hasData ? likeSnap.data!.docs.length : 0;
                                        return Text("❤️ $likeCount  ");
                                      },
                                    ),
                                    StreamBuilder<QuerySnapshot>(
                                      stream: FirebaseFirestore.instance
                                          .collection("posts")
                                          .doc(postId)
                                          .collection("comments")
                                          .snapshots(),
                                      builder: (context, commentSnap) {
                                        final commentCount = commentSnap.hasData ? commentSnap.data!.docs.length : 0;
                                        return Text("💬 $commentCount");
                                      },
                                    ),
                                  ],
                                )
                              ],
                            ),
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

  Widget _field(TextEditingController controller, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.teal),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        ),
      ),
    );
  }

  Widget _readonlyField(String text, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: TextEditingController(text: text),
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.email, color: Colors.grey),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        ),
      ),
    );
  }
}