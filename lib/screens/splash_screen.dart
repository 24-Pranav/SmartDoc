import 'dart:async';
import 'package:flutter/material.dart';
import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:smart_doc/screens/role_selection_screen.dart';
import 'package:lottie/lottie.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _showText = false;
  bool _showTagline = false;
  bool _isSmartAnimationFinished = false;
  bool _isDocAnimationFinished = false;

  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 500), () => setState(() => _showText = true));
    Timer(const Duration(milliseconds: 1800), () => setState(() => _showTagline = true));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSplashScreen(
      duration: 3500,
      splash: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A237E), Color(0xFF03A9F4)],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_showText)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _isSmartAnimationFinished ? _buildStaticSmartText() : _buildAnimatedSmartText(),
                    if (_isSmartAnimationFinished)
                      _isDocAnimationFinished ? _buildStaticDocText() : _buildAnimatedDocText(),
                  ],
                ),
              const SizedBox(height: 15),
              if (_showTagline)
                 _buildTaglineText(),
              const SizedBox(height: 40),
              Lottie.asset(
                'assets/loader.json',
                height: 90,
              ),
            ],
          ),
        ),
      ),
      nextScreen: const RoleSelectionScreen(),
      splashTransition: SplashTransition.fadeTransition,
      backgroundColor: const Color(0xFF1A237E),
    );
  }

  Widget _buildAnimatedSmartText() {
    return AnimatedTextKit(
      isRepeatingAnimation: false,
      animatedTexts: [
        TypewriterAnimatedText(
          'Smart',
          speed: const Duration(milliseconds: 150),
          cursor: '',
          textStyle: const TextStyle(
            fontSize: 52,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 2.0,
          ),
        ),
      ],
      onFinished: () {
        if (mounted) {
          setState(() {
            _isSmartAnimationFinished = true;
          });
        }
      },
    );
  }

  Widget _buildAnimatedDocText() {
    return AnimatedTextKit(
      isRepeatingAnimation: false,
      animatedTexts: [
        TypewriterAnimatedText(
          'Doc',
          speed: const Duration(milliseconds: 150),
          cursor: '|',
          textStyle: TextStyle(
            fontSize: 52,
            fontWeight: FontWeight.bold,
            color: Colors.lightBlue[200],
            letterSpacing: 2.0,
          ),
        ),
      ],
      onFinished: () {
        if (mounted) {
          setState(() {
            _isDocAnimationFinished = true;
          });
        }
      },
    );
  }

  Widget _buildStaticSmartText() {
    return const Text(
      'Smart',
      style: TextStyle(
        fontSize: 52,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        letterSpacing: 2.0,
      ),
    );
  }

  Widget _buildStaticDocText() {
    return Text(
      'Doc',
      style: TextStyle(
        fontSize: 52,
        fontWeight: FontWeight.bold,
        color: Colors.lightBlue[200],
        letterSpacing: 2.0,
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
