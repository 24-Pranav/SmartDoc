import 'dart:async';
import 'package:flutter/material.dart';
import 'package:smart_doc/screens/role_selection_screen.dart';
import 'package:lottie/lottie.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(
      const Duration(seconds: 4),
      () => Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A237E), Color(0xFF03A9F4)],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildAnimatedText(),
              ],
            ),
            const SizedBox(height: 15),
            _buildTaglineText(),
            const SizedBox(height: 40),
            Lottie.asset(
              'assets/loader.json',
              height: 90,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedText() {
    return DefaultTextStyle(
      style: const TextStyle(
        fontSize: 52,
        fontWeight: FontWeight.bold,
        letterSpacing: 2.0,
      ),
      child: AnimatedTextKit(
        isRepeatingAnimation: false,
        animatedTexts: [
          TyperAnimatedText(
            'SmartDoc',
            speed: const Duration(milliseconds: 150),
          ),
        ],
      ),
    );
  }

  Widget _buildTaglineText() {
    return AnimatedTextKit(
      isRepeatingAnimation: false,
      animatedTexts: [
        FadeAnimatedText(
          'Managing documents, intelligently.',
          duration: const Duration(milliseconds: 1200),
          textStyle: const TextStyle(
            fontSize: 18,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}
