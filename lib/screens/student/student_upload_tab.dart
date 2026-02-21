
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
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';

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

  Future<void> _scanDocument() async {
    try {
      final List<String> documentPaths = await DocumentScanner.instance.scanDocument(
        options: DocumentScannerOptions(
          documentScannerMode: DocumentScannerMode.full,
          resultFormat: ResultFormat.pdf,
          isGalleryImportAllowed: true,
        ),
      );
      if (documentPaths.isNotEmpty) {
        setState(() {
          _selectedFile = File(documentPaths.first);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to scan document: $e'),
        ),
      );
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
            throw Exception('No text could be extracted from the image.');
          }

          final aiResponse = await _aiService.verifyDocument(
              extractedText, _selectedCategory!, userName);
          final aiStatus =
          (aiResponse['status'] as String? ?? 'pending').toLowerCase();

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

      final downloadUrl =
      await _supabaseService.uploadFile(_selectedFile!, documentId, user.id);

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
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Upload Document',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Images (JPG, PNG) will be verified automatically. PDFs will be sent for faculty review.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Select Document Category',
                labelStyle: const TextStyle(color: Colors.black54),
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                  BorderSide(color: Theme.of(context).primaryColor, width: 2),
                ),
              ),
              items: _categories.map((String category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedCategory = newValue;
                });
              },
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _pickFile,
              child: DottedBorder(
                borderType: BorderType.RRect,
                radius: const Radius.circular(12),
                color: Colors.grey.shade400,
                strokeWidth: 2,
                dashPattern: const [8, 4],
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _selectedFile == null
                      ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cloud_upload_outlined,
                        size: 60,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Tap to select a file',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'JPG, PNG or PDF',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black45,
                        ),
                      ),
                    ],
                  )
                      : Stack(
                    alignment: Alignment.center,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle,
                              size: 60,
                              color: Theme.of(context).primaryColor),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16.0),
                            child: Text(
                              _selectedFile!.path.split('/').last,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IconButton(
                          icon: const Icon(Icons.close,
                              color: Colors.redAccent),
                          onPressed: _clearSelection,
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text('Scan Document'),
              onPressed: _scanDocument,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 32),
            _isUploading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
              icon: const Icon(Icons.upload_file_rounded),
              label: const Text('Upload and Verify'),
              onPressed: _uploadAndProcessFile,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Theme.of(context).primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
