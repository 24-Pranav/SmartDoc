import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_doc/services/firebase_service.dart';
import 'package:smart_doc/services/supabase_service.dart';
import 'package:smart_doc/widgets/message_box.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:smart_doc/services/ocr_service.dart';

class StudentUploadTab extends StatefulWidget {
  const StudentUploadTab({super.key});

  @override
  State<StudentUploadTab> createState() => _StudentUploadTabState();
}

class _StudentUploadTabState extends State<StudentUploadTab> {
  bool _isLoading = false;
  File? _selectedFile;
  final FirebaseService _firebaseService = FirebaseService();
  final SupabaseService _supabaseService = SupabaseService();
  final ImagePicker _picker = ImagePicker();
  final OcrService _ocrService = OcrService();

  Future<void> _requestPermissions() async {
    await Permission.camera.request();
    await Permission.photos.request();
  }

  Future<File?> _startDocumentScan() async {
    final DocumentScanner documentScanner = DocumentScanner(
      options: DocumentScannerOptions(
        mode: ScannerMode.full,
        pageLimit: 1,
      ),
    );

    try {
      final DocumentScanningResult result = await documentScanner.scanDocument();

      if (result.images.isNotEmpty) {
        return File(result.images.first);
      }
    } catch (e) {
      if (mounted) {
        showMessageBox(context, 'Error', 'Failed to scan document: $e');
      }
    }
    return null;
  }

  Future<File?> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 50, // Compress image
    );

    if (pickedFile != null) {
      // Copy the file to a safe directory
      final directory = await getApplicationDocumentsDirectory();
      final newPath = '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final File savedImage = await File(pickedFile.path).copy(newPath);
      return savedImage;
    }
    return null;
  }

  Future<File?> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      // Copy the file to a safe directory
      final directory = await getApplicationDocumentsDirectory();
      final newPath = '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.pdf';
      final File savedPdf = await File(result.files.single.path!).copy(newPath);
      return savedPdf;
    }
    return null;
  }

  void _showUploadOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Scan Document'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadFile(_startDocumentScan);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Upload from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadFile(() => _pickImage(ImageSource.gallery));
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined),
              title: const Text('Upload PDF'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadFile(_pickPdf);
              },
            ),
          ],
        );
      },
    );
  }


  Future<void> _pickAndUploadFile(Future<File?> Function() pickFunction) async {
    if (_isLoading) return;

    await _requestPermissions();

    try {
      final file = await pickFunction();

      if (file != null) {
        final isImage = ['.jpg', '.jpeg', '.png'].any((ext) => file.path.toLowerCase().endsWith(ext));

        if (isImage) {
          setState(() => _isLoading = true);
          final text = await _ocrService.processImage(file);
          final isExpired = _ocrService.isDocumentExpired(text);
          setState(() => _isLoading = false);

          if (isExpired) {
            if (mounted) {
              showMessageBox(context, 'Validation Failed', 'The document appears to be expired and cannot be uploaded.');
            }
            return; // Stop the process
          }
        }

        setState(() {
          _selectedFile = file;
        });

      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No file selected.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        showMessageBox(context, 'Error', 'Failed to pick file: $e');
        setState(() => _isLoading = false);
      }
    }
  }

  void _showUploadDialog(File file) {
    final TextEditingController nameController = TextEditingController();
    String? selectedCategory;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: const Text('Upload Document'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Document Name'),
                ),
                const SizedBox(height: 16),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('categories').orderBy('name').snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return const Text('Error loading categories');
                    }

                    final categories = snapshot.data!.docs
                        .map((doc) => doc['name'] as String)
                        .toList();

                    if (selectedCategory != null && !categories.contains(selectedCategory)) {
                      selectedCategory = null;
                    }

                    return DropdownButtonFormField<String>(
                      hint: const Text('Select Category'),
                      value: selectedCategory,
                      isExpanded: true,
                      items: categories.map((String category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          selectedCategory = newValue;
                        });
                      },
                      validator: (value) => value == null ? 'Please select a category' : null,
                    );
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.of(context).pop(),
              ),
              ElevatedButton(
                child: const Text('Upload'),
                onPressed: () {
                  if (nameController.text.isNotEmpty && selectedCategory != null) {
                    Navigator.of(context).pop();
                    _uploadDocument(file, nameController.text, selectedCategory!);
                  } else {
                    showMessageBox(context, 'Error', 'Please provide a name and category.');
                  }
                },
              ),
            ],
          );
        });
      },
    );
  }

  Future<void> _uploadDocument(File file, String name, String category) async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) {
          showMessageBox(context, 'Error', 'User not logged in. Please log in again.');
        }
        return;
      }
      final fileType = file.path.split('.').last;
      final fileUrl = await _supabaseService.uploadFile(file, name, user.uid);
      await _firebaseService.saveDocumentMetadata(name, category, fileType, fileUrl);

      if (mounted) {
        showMessageBox(context, 'Success', 'Document uploaded successfully.');
      }
      setState(() {
        _selectedFile = null;
      });
    } catch (e) {
      if (mounted) {
        showMessageBox(context, 'Error', 'Failed to upload document: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_selectedFile != null)
                Column(
                  children: [
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: _selectedFile!.path.endsWith('.pdf')
                          ? const Icon(Icons.picture_as_pdf, size: 100)
                          : Image.file(_selectedFile!, fit: BoxFit.cover, width: double.infinity),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          icon: const Icon(Icons.clear),
                          label: const Text('Clear'),
                          onPressed: () {
                            setState(() {
                              _selectedFile = null;
                            });
                          },
                        ),
                      ],
                    )
                  ],
                )
              else
                GestureDetector(
                  onTap: _showUploadOptions,
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cloud_upload_outlined, size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'Tap to select a document',
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 40),
              ElevatedButton(
                child: const Text('Upload Document'),
                onPressed: _isLoading || _selectedFile == null
                    ? null
                    : () => _showUploadDialog(_selectedFile!),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
