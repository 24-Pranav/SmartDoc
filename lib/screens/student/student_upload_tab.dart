import 'dart:io';
import 'dart:typed_data';
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
    final scanner = DocumentScanner(
      options: DocumentScannerOptions(
        documentFormats: const {DocumentFormat.jpeg},
        mode: ScannerMode.full,
        isGalleryImport: true,
        pageLimit: 5,
      ),
    );
    try {
      final DocumentScanningResult result = await scanner.scanDocument();

      final images = result.images;
      if (images != null && images.isNotEmpty) {
        setState(() {
          _selectedFile = File(images.first);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to scan document: $e'),
          ),
        );
      }
    } finally {
      scanner.close();
    }
  }


  void _clearSelection() {
    setState(() {
      _selectedFile = null;
    });
  }

  Future<String> _getFileExtension(File file) async {
    final Uint8List bytes = await file.readAsBytes();
    if (bytes.length > 4) {
      final header = bytes.sublist(0, 4);
      if (header[0] == 0xFF && header[1] == 0xD8 && header[2] == 0xFF) return 'jpeg';
      if (header[0] == 0x89 && header[1] == 0x50 && header[2] == 0x4E && header[3] == 0x47) return 'png';
      if (header[0] == 0x25 && header[1] == 0x50 && header[2] == 0x44 && header[3] == 0x46) return 'pdf';
    }
    return file.path.split('.').last.toLowerCase();
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
      final aiService = Provider.of<AIService>(context, listen: false);
      if (aiService.apiKey == 'API_KEY_NOT_FOUND') {
        throw Exception('API key not found. Please add it to your .env file.');
      }

      final existingDocsQuery = await FirebaseFirestore.instance
          .collection('documents')
          .where('studentId', isEqualTo: user.id)
          .where('category', isEqualTo: _selectedCategory)
          .limit(1)
          .get();

      bool isReplacing = false;

      if (existingDocsQuery.docs.isNotEmpty) {
        final existingDocSnapshot = existingDocsQuery.docs.first;
        final existingDoc = existingDocSnapshot.data();
        if (existingDoc['status'] == 'approved') {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text(
                  'This document is already approved. You cannot re-upload it.')));
          setState(() {
            _isUploading = false;
          });
          return;
        } else {
          isReplacing = true;
          try {
            if (existingDoc['doc_url'] != null) {
              await _supabaseService.deleteFile(existingDoc['doc_url']);
            }
            await existingDocSnapshot.reference.delete();
          } catch (e) {
            if (mounted) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Error Updating Document'),
                  content: Text(
                      'Could not remove the previous document. Please try again. Error: $e'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'))
                  ],
                ),
              );
            }
            setState(() {
              _isUploading = false;
            });
            return;
          }
        }
      }

      final String documentId = _uuid.v4();

      final String fileExtension = await _getFileExtension(_selectedFile!);
      final String docName = '${_selectedCategory!}.$fileExtension';

      String? aiStatusResult;
      String? aiCommentResult;
      String finalStatus;
      String statusMsg;
      final timelineEvents = <Map<String, dynamic>>[
        {
          'status': 'Document Uploaded',
          'timestamp': Timestamp.now(),
          'comment': 'Document has been uploaded by student.'
        }
      ];

      try {
        String extractedText;
        if (['jpg', 'jpeg', 'png'].contains(fileExtension)) {
          extractedText = await _ocrService.processImage(_selectedFile!);
        } else if (fileExtension == 'pdf') {
          extractedText = await _ocrService.processPdf(_selectedFile!);
        } else {
          throw Exception('Unsupported file type: $fileExtension. Please upload a JPG, PNG, or PDF.');
        }

        if (extractedText.isEmpty) {
          throw Exception('No text could be extracted from the document.');
        }

        final aiResponse = await aiService.verifyDocument(
            extractedText, _selectedCategory!, userName);

        aiStatusResult = (aiResponse['status'] as String? ?? 'pending').toLowerCase();
        aiCommentResult = aiResponse['comments'] as String?;

        if (aiStatusResult == 'approved') {
          finalStatus = 'approved';
          statusMsg = '✅ Document automatically approved by AI!';
        } else if (aiStatusResult == 'rejected') {
          finalStatus = 'rejected';
          statusMsg = '❌ Document automatically rejected by AI. Check comments.';
        } else {
          finalStatus = 'pending';
          statusMsg = '📄 AI could not verify. Sent for faculty review.';
        }

        timelineEvents.add({
          'status': 'AI Review Complete',
          'timestamp': Timestamp.now(),
          'comment': aiCommentResult ?? 'AI analysis performed.',
        });

      } catch (e) {
        // --- REVISED: More intelligent error handling for AI service failures ---
        finalStatus = 'pending';
        aiStatusResult = 'pending';
        String errorMessage = e.toString().toLowerCase();

        if (errorMessage.contains('503') || errorMessage.contains('unavailable')) {
            aiCommentResult = 'The AI verification service is temporarily busy. Your document has been sent for manual faculty review.';
            statusMsg = '⚠️ AI service is busy. Document sent for manual review.';
        } else if (errorMessage.contains('no text')) {
            aiCommentResult = 'No text could be extracted from the document, so it could not be verified automatically. It has been sent for manual review.';
            statusMsg = '⚠️ Could not read document. Sent for manual review.';
        } else {
            aiCommentResult = 'An unexpected error occurred during AI verification. Manual review is required.';
            statusMsg = '⚠️ AI check failed. Sent for manual faculty review.';
        }

        timelineEvents.add({
          'status': 'AI Verification Failed',
          'timestamp': Timestamp.now(),
          'comment': aiCommentResult, // Use the new, user-friendly comment
        });
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
        'doc_name': docName,
        'isArchived': false,
        'status': finalStatus,
        'ai_status': aiStatusResult,
        'ai_comment': aiCommentResult,
        'timeline': timelineEvents,
        'comments': null,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(isReplacing
                ? 'Document updated. $statusMsg'
                : statusMsg)));
      }

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
      appBar: AppBar(
        title: const Text('Upload Document'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            const Text(
              'All documents will now be verified automatically.',
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
