import 'dart:async';
import 'package:flutter/material.dart';
import '../main.dart'; // AuthWrapper access

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late Animation<double> _logoAnimation;

  late AnimationController _nameController;
  late Animation<double> _nameAnimation;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Logo bounce animation
    _logoController =
        AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _logoAnimation = Tween<double>(begin: 0.0, end: 20.0)
        .chain(CurveTween(curve: Curves.easeInOut))
        .animate(_logoController);
    _logoController.repeat(reverse: true);

    // App name scale animation
    _nameController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _nameAnimation = Tween<double>(begin: 0.9, end: 1.1)
        .chain(CurveTween(curve: Curves.easeInOut))
        .animate(_nameController);
    _nameController.repeat(reverse: true);

    // Fade-in company name
    _fadeController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _fadeAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(_fadeController);
    _fadeController.forward();

    // Navigate after 3 seconds
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AuthWrapper()),
      );
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _nameController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF00BFA5), Color(0xFF1DE9B6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo bounce animation
              AnimatedBuilder(
                animation: _logoAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, -_logoAnimation.value),
                    child: child,
                  );
                },
                child: Image.asset(
                  'assets/logo.png',
                  width: 120,
                  height: 120,
                ),
              ),
              const SizedBox(height: 20),
              // App name scale animation
              ScaleTransition(
                scale: _nameAnimation,
                child: const Text(
                  "HOSTEL HUB",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
              const SizedBox(height: 20),
              // Fade-in company name
              FadeTransition(
                opacity: _fadeAnimation,
                child: const Text(
                  "Powered by Mr. R - Group",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
