// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
//
// class ResetPasswordScreen extends StatefulWidget {
//   final String email;
//   const ResetPasswordScreen({super.key, required this.email});
//
//   @override
//   State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
// }
//
// class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
//   final _otpController = TextEditingController();
//   final _passwordController = TextEditingController();
//   bool _isLoading = false;
//
//   Future<void> resetPassword() async {
//     final otp = _otpController.text.trim();
//     final newPassword = _passwordController.text.trim();
//     if (otp.isEmpty || newPassword.isEmpty) return;
//
//     setState(() => _isLoading = true);
//
//     try {
//       // Fetch OTP from Firestore
//       final doc = await FirebaseFirestore.instance.collection('passwordResets').doc(widget.email).get();
//       if (!doc.exists) {
//         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('OTP not found')));
//         return;
//       }
//
//       final data = doc.data()!;
//       final savedOtp = data['otp'];
//       final createdAt = (data['createdAt'] as Timestamp).toDate();
//
//       // OTP expiration check: 5 mins
//       if (DateTime.now().difference(createdAt).inMinutes > 5) {
//         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('OTP expired')));
//         return;
//       }
//
//       if (savedOtp != otp) {
//         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid OTP')));
//         return;
//       }
//
//       // OTP valid: update password
//       final methods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(widget.email);
//       if (methods.isEmpty) {
//         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User not found')));
//         return;
//       }
//
//       // Sign in with temporary credential (anonymous login)
//       final user = (await FirebaseAuth.instance.signInAnonymously()).user;
//
//       // Update password using Firebase Admin or Functions
//       // Direct update not allowed from client-side for security
//       // Safe way: send password reset email
//       await FirebaseAuth.instance.sendPasswordResetEmail(email: widget.email);
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Password reset link sent. Check your email.')),
//       );
//
//       // Delete OTP after use
//       await FirebaseFirestore.instance.collection('passwordResets').doc(widget.email).delete();
//
//       Navigator.popUntil(context, (route) => route.isFirst);
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Reset Password')),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             TextField(
//               controller: _otpController,
//               decoration: const InputDecoration(labelText: 'Enter OTP'),
//             ),
//             TextField(
//               controller: _passwordController,
//               decoration: const InputDecoration(labelText: 'New Password'),
//               obscureText: true,
//             ),
//             const SizedBox(height: 20),
//             _isLoading
//                 ? const CircularProgressIndicator()
//                 : ElevatedButton(
//               onPressed: resetPassword,
//               child: const Text('Reset Password'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
