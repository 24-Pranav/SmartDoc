import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart_doc/models/document.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DocumentStorageService {
  final SupabaseClient _supabase;

  DocumentStorageService(this._supabase);

  Future<void> saveDocument(
      File file, String name, String category, String uploaderName) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    final extension = file.path.split('.').last;
    final fileName = '${user.uid}/${DateTime.now().millisecondsSinceEpoch}.$extension';

    await _supabase.storage.from('documents').upload(
          fileName,
          file,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
        );

    final url = _supabase.storage.from('documents').getPublicUrl(fileName);

    final docRef = FirebaseFirestore.instance.collection('documents').doc();

    // CORRECTED: Aligned with the Document model's constructor
    final document = Document(
      id: docRef.id,
      name: name,
      studentName: uploaderName,      // Corrected parameter name
      category: category,
      status: DocumentStatus.pending, // Corrected to use the enum
      studentId: user.uid,
      uploadedDate: DateTime.now(),   // Corrected parameter name
      url: url,
    );

    await docRef.set(document.toFirestore());
  }

  Future<void> deleteFileFromUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      final pathToRemove = uri.pathSegments.sublist(uri.pathSegments.indexOf('documents') + 1).join('/');
      await _supabase.storage.from('documents').remove([pathToRemove]);
    } catch (e) {
      // Log or handle the error appropriately
      print('Error deleting from Supabase Storage: $e');
      rethrow; // Re-throw the exception to be handled by the caller
    }
  }
}
