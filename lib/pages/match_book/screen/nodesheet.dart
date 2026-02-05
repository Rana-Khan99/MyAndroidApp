import 'package:flutter/material.dart';

class StudentAttendancePage extends StatelessWidget {
  const StudentAttendancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Student Attendance"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text(
              "Student Attendance Page",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text("এখানে স্টুডেন্ট হাজিরা নেওয়া হবে"),
          ],
        ),
      ),
    );
  }
}
