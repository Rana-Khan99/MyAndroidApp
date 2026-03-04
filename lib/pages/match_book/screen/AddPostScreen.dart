import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _locationController = TextEditingController();
  final _instituteController = TextEditingController();
  final _matchController = TextEditingController();

  bool _loading = false;

  // 🔍 Generate search keywords
  List<String> _generateKeywords(String text) {
    text = text.toLowerCase().trim();
    if (text.isEmpty) return [];
    List<String> keywords = [];
    for (int i = 1; i <= text.length; i++) {
      keywords.add(text.substring(0, i));
    }
    return keywords;
  }

  // 🚀 Upload post
  Future<void> _uploadPost() async {
    if (_titleController.text.trim().isEmpty ||
        _descController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Title & Description required")),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      final List<String> searchKeywords = [
        ..._generateKeywords(_locationController.text),
        ..._generateKeywords(_instituteController.text),
        ..._generateKeywords(_matchController.text),
      ];

      await FirebaseFirestore.instance.collection("posts").add({
        "uid": uid,
        "title": _titleController.text.trim(),
        "description": _descController.text.trim(),
        "location": _locationController.text.trim().toLowerCase(),
        "institute": _instituteController.text.trim().toLowerCase(),
        "match_hostel": _matchController.text.trim().toLowerCase(),
        "searchKeywords": searchKeywords,
        "imageUrl": "", // 🔥 no image
        "timestamp": FieldValue.serverTimestamp(),
      });

      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Post failed: $e")),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // 🧱 Input field widget
  Widget _inputField(
      String label,
      TextEditingController controller, {
        int maxLines = 1,
      }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: InputBorder.none,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _locationController.dispose();
    _instituteController.dispose();
    _matchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Create Post"),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _inputField("Post Title", _titleController),
            _inputField("Post  Description", _descController, maxLines: 4),
            _inputField("Institute / College / Office  Name", _instituteController),
            _inputField("Mess / Hostel / Home  Name", _matchController),
            _inputField("Location", _locationController),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _uploadPost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  "Publish Post",
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
