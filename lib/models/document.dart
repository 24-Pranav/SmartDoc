import 'package:cloud_firestore/cloud_firestore.dart';

enum DocumentStatus {
  pending,
  approved,
  rejected,
  resubmission,
}

class Document {
  final String id;
  final String name;
  final String studentName;
  final String category;
  final DocumentStatus status;
  final String studentId;
  final DateTime uploadedDate;
  final String? url;

  // Optional fields for verification flow
  final String? verifiedByUserId;
  final DateTime? verificationDate;
  final String? comments;

  Document({
    required this.id,
    required this.name,
    required this.studentName,
    required this.category,
    required this.status,
    required this.studentId,
    required this.uploadedDate,
    this.url,
    this.verifiedByUserId,
    this.verificationDate,
    this.comments,
  });

  factory Document.fromFirestore(Map<String, dynamic> data, String documentId) {
    DateTime? safeTimestampParse(dynamic timestamp) {
      if (timestamp is Timestamp) {
        return timestamp.toDate();
      }
      return null;
    }

    return Document(
      id: documentId,
      name: data['doc_name'] ?? 'Untitled Document',
      studentName: data['uploader_name'] ?? 'Unknown Name',
      category: data['category'] ?? 'Uncategorized',
      status: DocumentStatus.values.firstWhere(
            (e) => e.name == (data['status'] ?? 'pending'),
        orElse: () => DocumentStatus.pending,
      ),
      studentId: data['studentId'] ?? '',
      uploadedDate: safeTimestampParse(data['uploaded_at']) ?? DateTime.now(),
      url: data['doc_url'],
      verifiedByUserId: data['verified_by_user_id'],
      verificationDate: safeTimestampParse(data['verification_date']),
      comments: data['comments'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'doc_name': name,
      'uploader_name': studentName,
      'category': category,
      'status': status.name,
      'studentId': studentId,
      'uploaded_at': Timestamp.fromDate(uploadedDate),
      'doc_url': url,
      'verified_by_user_id': verifiedByUserId,
      'verification_date': verificationDate != null ? Timestamp.fromDate(verificationDate!) : null,
      'comments': comments,
    };
  }
}