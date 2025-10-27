import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart_doc/models/document.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DocumentStorageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SupabaseClient _supabase = Supabase.instance.client;

  Stream<List<Document>> getDocuments() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.value([]);
    }
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('documents')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Document.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  Future<void> saveDocument(
      File file, String name, String category, String fileType) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    final fileName = '${user.uid}/${DateTime.now().millisecondsSinceEpoch}.$fileType';

    final response = await _supabase.storage.from('documents').upload(
          fileName,
          file,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
        );

    final downloadUrl = _supabase.storage.from('documents').getPublicUrl(fileName);

    final docRef = _firestore.collection('users').doc(user.uid).collection('documents').doc();

    final document = Document(
      id: docRef.id,
      name: name,
      category: category,
      fileType: fileType,
      uploadedByUserId: user.uid,
      uploadedDate: DateTime.now().toIso8601String(),
      downloadUrl: downloadUrl,
    );

    await docRef.set(document.toFirestore());
  }

  Future<void> deleteDocument(String documentId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }
    final docRef = _firestore.collection('users').doc(user.uid).collection('documents').doc(documentId);
    final docSnapshot = await docRef.get();
    final document = Document.fromFirestore(docSnapshot.data()!, docSnapshot.id);

    if (document.downloadUrl != null) {
      final path = Uri.parse(document.downloadUrl!).pathSegments.last;
      try {
        await _supabase.storage.from('documents').remove([path]);
      } catch (e) {
        print('Error deleting from Supabase: $e');
      }
    }

    await docRef.delete();
  }
}
