import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/document_storage_service.dart';

class FilterScreen extends StatefulWidget {
  final String imagePath;

  const FilterScreen({super.key, required this.imagePath});

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  final DocumentStorageService _storageService = DocumentStorageService();
  bool _isSaving = false;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();

  static const _tempImagePathKey = 'temp_image_path';

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _cleanupTempFiles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tempImagePathKey);

      final tempFile = File(widget.imagePath);
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    } catch (e) {
      print('Error during cleanup: $e');
    }
  }

  Future<void> _saveDocument() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final name = _nameController.text;
      final category = _categoryController.text;
      final fileType = widget.imagePath.split('.').last;

      await _storageService.saveDocument(
        File(widget.imagePath),
        name,
        category,
        fileType,
      );

      await _cleanupTempFiles();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(); // Go back from FilterScreen
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving document: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _cleanupTempFiles();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Finalize Document'),
          actions: [
            if (_isSaving)
              const Padding(
                padding: EdgeInsets.only(right: 16.0),
                child: Center(child: CircularProgressIndicator(color: Colors.white)),
              )
            else
              IconButton(
                icon: const Icon(Icons.check),
                onPressed: _saveDocument,
                tooltip: 'Save Document',
              ),
          ],
        ),
        body: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Image.file(File(widget.imagePath)),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Document Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a document name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _categoryController,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a category';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
