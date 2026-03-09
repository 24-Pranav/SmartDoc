import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  // Unnecessary re-authentication removed. The client is authenticated at login.

  Future<String> uploadFile(File file, String documentId, String userId) async {
    final fileExtension = file.path.split('.').last.toLowerCase();
    final fileName = '$documentId.$fileExtension';
    final filePath = '$userId/$fileName';

    try {
      // The Supabase client will use its existing, valid session for this upload.
      await _client.storage.from('documents').upload(
            filePath,
            file,
            fileOptions: FileOptions(
              upsert: true,
              // Explicitly set the content type for PDF files to ensure proper rendering.
              contentType: fileExtension == 'pdf' ? 'application/pdf' : null,
            ),
          );

      final downloadUrl = _client.storage.from('documents').getPublicUrl(filePath);
      return downloadUrl;
    } on StorageException catch (e) {
      // If a row-level security error happens now, it points to a config issue,
      // not an expired token.
      throw Exception('Supabase storage error: ${e.message}');
    } catch (e) {
      throw Exception('An unexpected error occurred during file upload: $e');
    }
  }

  Future<void> deleteFile(String documentUrl) async {
    try {
      final path = Uri.parse(documentUrl).pathSegments.last;
      await _client.storage.from('documents').remove([path]);
    } on StorageException catch (e) {
      if (e.statusCode != '404') {
        throw Exception('Supabase storage error on delete: ${e.message}');
      }
    } catch (e) {
      throw Exception('An unexpected error occurred during file deletion: $e');
    }
  }
}
