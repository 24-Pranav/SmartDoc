import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_doc/utils/show_message_box.dart'; // Assuming you have this helper

class StudentUploadTab extends StatefulWidget {
  const StudentUploadTab({Key? key}) : super(key: key);

  @override
  _StudentUploadTabState createState() => _StudentUploadTabState();
}

class _StudentUploadTabState extends State<StudentUploadTab> {
  File? _selectedFile;
  bool _isLoading = false;
  String? _selectedCategory;
  List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('document_categories').get();
      if (snapshot.docs.isNotEmpty) {
        setState(() {
          _categories = snapshot.docs.map((doc) => doc.id as String).toList();
        });
      }
    } catch (e) {
      if (mounted) {
        showMessageBox(context, 'Error', 'Failed to load categories: $e');
      }
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
        });
      }
    } catch (e) {
      if (mounted) {
        showMessageBox(context, 'Error', 'Failed to pick file: $e');
      }
    }
  }

  Future<void> _uploadDocument(File file, String docName, String category) async {
    if (FirebaseAuth.instance.currentUser == null) {
      showMessageBox(context, 'Error', 'You must be logged in to upload.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${docName.replaceAll(' ', '_')}';
      final storagePath = 'documents/${user.uid}/$fileName';

      // 1. Upload to Firebase Storage
      final ref = FirebaseStorage.instance.ref(storagePath);
      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask.whenComplete(() => null);
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // 2. Get uploader's name from 'users' collection
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final uploaderName = userDoc.data()?['name'] ?? 'Unknown User';

      // 3. Save metadata to Firestore
      await FirebaseFirestore.instance.collection('documents').add({
        'docName': docName,
        'docUrl': downloadUrl,
        'category': category,
        'uploaderId': user.uid,
        'uploaderName': uploaderName,
        'uploadedAt': Timestamp.now(),
        'status': 'pending', // or any initial status
      });

      setState(() {
        _selectedFile = null;
      });

      if (mounted) {
        showMessageBox(context, 'Success', 'Document uploaded successfully and is pending review.');
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        showMessageBox(context, 'Upload Error', e.message ?? 'An unknown error occurred.');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showUploadDialog(File file) {
    final nameController = TextEditingController();
    String? dialogSelectedCategory = _categories.isNotEmpty ? _categories[0] : null;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Document Details'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Document Name'),
                  ),
                  const SizedBox(height: 20),
                  if (_categories.isNotEmpty)
                    DropdownButton<String>(
                      isExpanded: true,
                      value: dialogSelectedCategory,
                      hint: const Text('Select Category'),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            dialogSelectedCategory = value;
                          });
                        }
                      },
                      items: _categories.map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    )
                  else
                    const Text('Loading categories...'),
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
                    if (nameController.text.isNotEmpty && dialogSelectedCategory != null) {
                      Navigator.of(context).pop();
                      _uploadDocument(file, nameController.text, dialogSelectedCategory!);
                    } else {
                      showMessageBox(context, 'Error', 'Please provide a name and select a category.');
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Document'),
        centerTitle: true,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onTap: _pickFile,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade400, width: 2, style: BorderStyle.solid),
                ),
                child: _selectedFile != null
                    ? Center(child: Text(_selectedFile!.path.split('/').last, textAlign: TextAlign.center))
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cloud_upload_outlined, size: 80, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text('Tap to select a document', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 40),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              ElevatedButton.icon(
                icon: const Icon(Icons.file_upload),
                label: const Text('Upload Document'),
                onPressed: _isLoading || _selectedFile == null ? null : () => _showUploadDialog(_selectedFile!),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
