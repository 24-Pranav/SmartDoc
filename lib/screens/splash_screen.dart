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
  bool _showLogo = false;
  bool _showText = false;
  bool _showTagline = false;
  bool _isSmartAnimationFinished = false;
  bool _isDocAnimationFinished = false;

  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 300), () => setState(() => _showLogo = true));
    Timer(const Duration(milliseconds: 1000), () => setState(() => _showText = true));
    Timer(const Duration(milliseconds: 2200), () => setState(() => _showTagline = true));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSplashScreen(
      duration: 4000,
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
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedScale(
                  scale: _showLogo ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutBack,
                  child: Image.asset(
                    'assets/images/logo.png',
                    height: 120,
                  ),
                ),
                const SizedBox(height: 25),
                if (_showText)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _isSmartAnimationFinished ? _buildStaticSmartText() : _buildAnimatedSmartText(),
                      if (_isSmartAnimationFinished)
                        _isDocAnimationFinished ? _buildStaticDocText() : _buildAnimatedDocText(),
                    ],
                  ),
                const SizedBox(height: 10),
                if (_showTagline)
                   _buildTaglineText(),
                const SizedBox(height: 30),
                Lottie.asset(
                  'assets/loader.json',
                  height: 80,
                ),
              ],
            ),
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
            fontSize: 38,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.5,
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
            fontSize: 38,
            fontWeight: FontWeight.bold,
            color: Colors.lightBlue[200],
            letterSpacing: 1.5,
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
        fontSize: 38,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildStaticDocText() {
    return Text(
      'Doc',
      style: TextStyle(
        fontSize: 38,
        fontWeight: FontWeight.bold,
        color: Colors.lightBlue[200],
        letterSpacing: 1.5,
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
            fontSize: 16,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}
