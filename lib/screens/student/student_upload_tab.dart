import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:smart_doc/models/user.dart';
import 'package:smart_doc/providers/user_provider.dart';
import 'package:smart_doc/services/ai_service.dart';
import 'package:smart_doc/services/firebase_service.dart';
import 'package:smart_doc/services/ocr_service.dart';
import 'package:smart_doc/services/supabase_service.dart';
import 'package:uuid/uuid.dart';
import 'package:dotted_border/dotted_border.dart';

class StudentUploadTab extends StatefulWidget {
  const StudentUploadTab({super.key});

  @override
  State<StudentUploadTab> createState() => _StudentUploadTabState();
}

class _StudentUploadTabState extends State<StudentUploadTab> {
  final OcrService _ocrService = OcrService();
  final AIService _aiService =
  AIService(apiKey: 'YOUR_API_KEY_HERE'); // Move this to .env in production
  final SupabaseService _supabaseService = SupabaseService();
  final FirebaseService _firebaseService = FirebaseService();
  final Uuid _uuid = const Uuid();

  bool _isUploading = false;
  String? _selectedCategory;
  List<String> _categories = [];
  File? _selectedFile;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      final snapshot =
      await FirebaseFirestore.instance.collection('categories').get();
      if (mounted) {
        setState(() {
          _categories =
              snapshot.docs.map((doc) => doc['name'] as String).toList();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load categories: $e')));
      }
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );

    if (result != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
      });
    }
  }

  void _clearSelection() {
    setState(() {
      _selectedFile = null;
    });
  }

  Future<void> _uploadAndProcessFile() async {
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a category first.')));
      return;
    }

    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a file to upload.')));
      return;
    }

    final User? user =
        Provider.of<UserProvider>(context, listen: false).user;

    if (user == null || user.name == null || user.name!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not verify user. Please log in again.')));
      return;
    }

    final String userName = user.name!;

    setState(() {
      _isUploading = true;
    });

    try {
      final existingDocsQuery = await FirebaseFirestore.instance
          .collection('documents')
          .where('studentId', isEqualTo: user.id)
          .where('category', isEqualTo: _selectedCategory)
          .limit(1)
          .get();

      final bool isUpdating = existingDocsQuery.docs.isNotEmpty;
      final String documentId =
      isUpdating ? existingDocsQuery.docs.first.id : _uuid.v4();

      String status;
      String comments;
      final String fileExtension =
      _selectedFile!.path.split('.').last.toLowerCase();

      try {
        if (['jpg', 'jpeg', 'png'].contains(fileExtension)) {
          final extractedText =
          await _ocrService.processImage(_selectedFile!);

          if (extractedText.isEmpty) {
            throw Exception(
                'No text could be extracted from the image.');
          }

          final aiResponse = await _aiService.verifyDocument(
              extractedText, _selectedCategory!, userName);

          final aiStatus =
          (aiResponse['status'] as String? ?? 'pending')
              .toLowerCase();

          if (aiStatus == 'approved') {
            status = 'approved';
            comments = aiResponse['comments'] as String? ??
                'Automatically approved by AI.';
          } else {
            status = 'pending';
            comments = aiResponse['comments'] as String? ??
                'Sent for faculty review.';
          }
        } else {
          status = 'pending';
          comments = 'PDF requires manual faculty review.';
        }
      } catch (e) {
        status = 'pending';
        comments =
        'Verification failed. Manual review required. ${e.toString()}';
      }

      final downloadUrl = await _supabaseService.uploadFile(
          _selectedFile!, documentId, user.id);

      await FirebaseFirestore.instance
          .collection('documents')
          .doc(documentId)
          .set({
        'id': documentId,
        'studentId': user.id,
        'uploader_name': userName,
        'category': _selectedCategory,
        'doc_url': downloadUrl,
        'uploaded_at': Timestamp.now(),
        'status': status,
        'comments': comments,
        'isArchived': false,
        'doc_name': _selectedFile!.path.split('/').last,
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isUpdating
              ? 'Document updated.'
              : 'Document uploaded successfully.')));

      setState(() {
        _selectedFile = null;
        _selectedCategory = null;
      });
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text(e.toString()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Upload Document',
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Select Category',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              items: _categories
                  .map((c) =>
                  DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) =>
                  setState(() => _selectedCategory = v),
            ),

            const SizedBox(height: 24),

            GestureDetector(
              onTap: _pickFile,
              child: DottedBorder(
                options: RoundedRectDottedBorderOptions(
                  radius: const Radius.circular(12),
                  dashPattern: const [8, 4],
                  strokeWidth: 2,
                  color: Colors.grey.shade400,
                ),
                child: Container(
                  height: 200,
                  alignment: Alignment.center,
                  child: _selectedFile == null
                      ? const Column(
                    mainAxisAlignment:
                    MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_upload_outlined,
                          size: 60,
                          color: Colors.grey),
                      SizedBox(height: 12),
                      Text('Tap to select a file'),
                    ],
                  )
                      : Text(
                    _selectedFile!.path
                        .split('/')
                        .last,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            _isUploading
                ? const Center(
                child: CircularProgressIndicator())
                : ElevatedButton(
              onPressed: _uploadAndProcessFile,
              child:
              const Text('Upload and Verify'),
            ),
          ],
        ),
      ),
    );
  }
}
