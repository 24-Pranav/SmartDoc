import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:smart_doc/models/role.dart';
import 'package:smart_doc/models/user.dart' as model;
import 'package:smart_doc/providers/user_provider.dart';
import 'package:smart_doc/screens/faculty/faculty_registration_screen.dart';
import 'package:smart_doc/screens/faculty/faculty_waiting_screen.dart';
import 'package:smart_doc/screens/student/registration_screen.dart';
import 'package:smart_doc/widgets/message_box.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../utils/string_extensions.dart';
import 'common/auth_wrapper.dart';

class LoginScreen extends StatefulWidget {
  final Role role;
  const LoginScreen({super.key, required this.role});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _resetPassword() async {
    if (_emailController.text.isEmpty) {
      showMessageBox(context, 'Error', 'Please enter your email to reset your password.');
      return;
    }
    try {
      await _auth.sendPasswordResetEmail(email: _emailController.text);
      showMessageBox(context, 'Success', 'Password reset email sent. Please check your inbox.');
    } catch (e) {
      showMessageBox(context, 'Error', 'Failed to send password reset email. Please try again.');
    }
  }

  void _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      showMessageBox(context, 'Error', 'Please fill all fields.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_emailController.text == 'deshmukhvivek596@gmail.com' &&
          _passwordController.text == '05102005') {
        try {
          final UserCredential userCredential =
              await _auth.signInWithEmailAndPassword(
            email: _emailController.text,
            password: _passwordController.text,
          );
          final user = userCredential.user;
          if (user != null) {
            await _firestore.collection('users').doc(user.uid).set({
              'email': user.email,
              'role': 'admin',
              'fullName': 'Vivek Deshmukh',
            }, SetOptions(merge: true));
          }
        } on FirebaseAuthException catch (e) {
          if (e.code == 'user-not-found') {
            final UserCredential userCredential =
                await _auth.createUserWithEmailAndPassword(
              email: _emailController.text,
              password: _passwordController.text,
            );
            final user = userCredential.user;
            if (user != null) {
              await _firestore.collection('users').doc(user.uid).set({
                'email': user.email,
                'role': 'admin',
                'fullName': 'Vivek Deshmukh',
              });
            }
          } else {
            rethrow;
          }
        }

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AuthWrapper()),
          );
        }
        return;
      }

      final UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (widget.role == Role.faculty) {
        final DocumentSnapshot facultyDoc = await _firestore
            .collection('faculty')
            .doc(userCredential.user!.uid)
            .get();

        if (!facultyDoc.exists) {
          await _auth.signOut();
          throw Exception('You are not registered as a faculty member.');
        }

        final facultyData = facultyDoc.data() as Map<String, dynamic>?;
        final status = facultyData?['status'];
        final String statusString = status is String ? status : '';

        if (statusString == 'pending') {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => const FacultyWaitingScreen()),
            );
          }
        } else if (statusString == 'approved') {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const AuthWrapper()),
            );
          }
        } else {
          await _auth.signOut();
          throw Exception(
              'Your registration has been denied or an error occurred.');
        }
      } else {
        final DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        if (!userDoc.exists) {
          throw Exception('User data not found.');
        }

        final user = model.User.fromFirestore(
            userDoc.data() as Map<String, dynamic>, userDoc.id);
        if (mounted) {
          Provider.of<UserProvider>(context, listen: false).setUser(user);
        }

        if (user.role != widget.role) {
          await _auth.signOut();
          throw Exception('Selected role does not match user account role.');
        } else {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const AuthWrapper()),
            );
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String errorMessage = 'An unknown error occurred.';
        if (e.code == 'user-not-found') {
          errorMessage = 'No user found for that email.';
        } else if (e.code == 'wrong-password') {
          errorMessage = 'Wrong password provided for that user.';
        } else if (e.code == 'invalid-email') {
          errorMessage = 'The email address is not valid.';
        }
        showMessageBox(context, 'Login Failed', errorMessage);
      }
    } catch (e) {
      if (mounted) {
        showMessageBox(
            context, 'Login Failed', e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                const SizedBox(height: 48.0),
                _buildLoginForm(),
                const SizedBox(height: 24.0),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Image.asset('assets/images/logo.png', height: 100),
        const SizedBox(height: 16.0),
        Text(
          'Welcome Back!',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8.0),
        Text(
          'Login as ${widget.role.toString().split('.').last.capitalize()}',
          style: TextStyle(
            fontSize: 18,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Column(
      children: [
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'Email',
            hintText: 'user@college.edu',
            prefixIcon: const Icon(Icons.email_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(color: Colors.blueAccent, width: 2.0),
            ),
          ),
        ),
        const SizedBox(height: 16.0),
        TextFormField(
          controller: _passwordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'Password',
            hintText: 'password',
            prefixIcon: const Icon(Icons.lock_outline),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(color: Colors.blueAccent, width: 2.0),
            ),
          ),
        ),
        const SizedBox(height: 24.0),
        _isLoading
            ? const CircularProgressIndicator()
            : SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    elevation: 5,
                  ),
                  child: const Text(
                    'Login',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
      ],
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        TextButton(
          onPressed: _resetPassword,
          child: const Text(
            'Forgot Password?',
            style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8.0),
        if (widget.role == Role.student)
          _buildSignUpButton(() {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      RegistrationScreen(role: widget.role)),
            );
          }),
        if (widget.role == Role.faculty)
          _buildSignUpButton(() {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      const FacultyRegistrationScreen()),
            );
          }),
      ],
    );
  }

  Widget _buildSignUpButton(VoidCallback onPressed) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Don't have an account?"),
        TextButton(
          onPressed: onPressed,
          child: const Text(
            'Sign Up',
            style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
