import 'dart:io';

import 'package:smart_doc/screens/student/student_dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smart_doc/models/role.dart';
import 'package:smart_doc/services/ocr_service.dart';

class RegistrationScreen extends StatefulWidget {
  final Role role;

  const RegistrationScreen({super.key, required this.role});

  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _studentNameController = TextEditingController();
  final _yearController = TextEditingController();
  final _sectionController = TextEditingController();
  final _studentIdController = TextEditingController();

  File? _studentIdCard;
  bool _isOcrInProgress = false;
  final OcrService _ocrService = OcrService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _studentNameController.dispose();
    _yearController.dispose();
    _sectionController.dispose();
    _studentIdController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _studentIdCard = File(pickedFile.path);
      });
    }
  }

  Future<void> _performOcr() async {
    if (_studentIdCard == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image first.')),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isOcrInProgress = true;
    });

    final String recognizedText = await _ocrService.processImage(_studentIdCard!);

    final expectedName = _studentNameController.text.trim().toLowerCase();
    final expectedId =
        _studentIdController.text.trim().replaceAll(RegExp(r'[^0-9]'), '');

    bool isNameFound = false;
    bool isIdFound = false;

    if (recognizedText.toLowerCase().contains(expectedName)) {
      isNameFound = true;
    }

    final ocrTextNumeric = recognizedText.replaceAll(RegExp(r'[^0-9]'), '');
    if (ocrTextNumeric.contains(expectedId)) {
      isIdFound = true;
    }

    if (isNameFound && isIdFound) {
      final existingUser = await _firestore
          .collection('users')
          .where('id', isEqualTo: _studentIdController.text.trim())
          .get();

      if (existingUser.docs.isNotEmpty) {
        setState(() {
          _isOcrInProgress = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('A user with this Student ID is already registered.')),
        );
      } else {
        _register();
      }
    } else {
      setState(() {
        _isOcrInProgress = false;
      });
      String errorMessage = 'OCR validation failed. ';
      if (!isNameFound && !isIdFound) {
        errorMessage += 'Could not find your name or student ID on the card.';
      } else if (!isNameFound) {
        errorMessage += 'Could not find your name on the card.';
      } else {
        errorMessage += 'Could not find your student ID on the card.';
      }
      errorMessage += ' Please check the details and the uploaded image.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }

  Future<void> _register() async {
    if (widget.role != Role.student && !_formKey.currentState!.validate()) {
      return;
    }

    final email = _emailController.text;
    final password = _passwordController.text;
    final studentName = _studentNameController.text;
    final year = _yearController.text;
    final section = _sectionController.text;
    final studentId = _studentIdController.text;
    final role = widget.role.toString().split('.').last;

    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      if (user != null) {
        final userData = {
          'email': email,
          'role': role,
          'name': studentName,
          if (widget.role == Role.student) ...{
            'year': year,
            'section': section,
            'id': studentId,
          }
        };

        await _firestore.collection('users').doc(user.uid).set(userData);

        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => const StudentDashboardScreen(initialIndex: 1),
            ),
            (route) => false,
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Registration failed')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isOcrInProgress = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.role.toString().split('.').last} Registration'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                if (widget.role == Role.student) ...[
                  _CustomInputField(
                    controller: _studentNameController,
                    label: 'Student Name',
                    icon: Icons.person,
                    validator: (value) =>
                        value!.isEmpty ? 'Please enter your name' : null,
                  ),
                  const SizedBox(height: 16),
                  _CustomInputField(
                    controller: _studentIdController,
                    label: 'Student ID',
                    icon: Icons.badge,
                    validator: (value) =>
                        value!.isEmpty ? 'Please enter your student ID' : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _CustomInputField(
                          controller: _yearController,
                          label: 'Year',
                          icon: Icons.calendar_today,
                          validator: (value) =>
                              value!.isEmpty ? 'Please enter your year' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _CustomInputField(
                          controller: _sectionController,
                          label: 'Section',
                          icon: Icons.group,
                          validator: (value) => value!.isEmpty
                              ? 'Please enter your section'
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildIdCardPicker(),
                  const SizedBox(height: 16),
                ],
                _CustomInputField(
                  controller: _emailController,
                  label: 'Email',
                  icon: Icons.email,
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter your email' : null,
                ),
                const SizedBox(height: 16),
                _CustomPasswordField(
                  controller: _passwordController,
                  label: 'Password',
                ),
                const SizedBox(height: 32),
                _isOcrInProgress
                    ? const CircularProgressIndicator()
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed:
                              widget.role == Role.student ? _performOcr : _register,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child:
                              const Text('Register', style: TextStyle(fontSize: 18)),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIdCardPicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(12),
        ),
        child: _studentIdCard == null
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt, size: 40, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('Upload Student ID Card', style: TextStyle(color: Colors.grey)),
                ],
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(_studentIdCard!, fit: BoxFit.cover),
              ),
      ),
    );
  }
}

class _CustomInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? Function(String?)? validator;

  const _CustomInputField({
    required this.controller,
    required this.label,
    required this.icon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: validator,
    );
  }
}

class _CustomPasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String label;

  const _CustomPasswordField({
    required this.controller,
    required this.label,
  });

  @override
  State<_CustomPasswordField> createState() => _CustomPasswordFieldState();
}

class _CustomPasswordFieldState extends State<_CustomPasswordField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscureText,
      decoration: InputDecoration(
        labelText: widget.label,
        prefixIcon: const Icon(Icons.lock),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureText ? Icons.visibility : Icons.visibility_off,
          ),
          onPressed: () {
            setState(() {
              _obscureText = !_obscureText;
            });
          },
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a password';
        }
        return null;
      },
    );
  }
}
