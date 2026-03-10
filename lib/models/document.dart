import 'package:cloud_firestore/cloud_firestore.dart';

// Represents a single event in the document's verification history.
class TimelineEvent {
  final String status;
  final DateTime timestamp;
  final String? comment; // Optional comment for certain events

  TimelineEvent({
    required this.status,
    required this.timestamp,
    this.comment,
  });

  // Creates a TimelineEvent from a map (typically from Firestore).
  factory TimelineEvent.fromMap(Map<String, dynamic> map) {
    return TimelineEvent(
      status: map['status'] ?? 'Unknown',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      comment: map['comment'],
    );
  }

  // Converts a TimelineEvent to a map for storing in Firestore.
  Map<String, dynamic> toMap() {
    return {
      'status': status,
      'timestamp': Timestamp.fromDate(timestamp),
      'comment': comment,
    };
  }
}

enum DocumentStatus {
  pending,
  approved,
  rejected,
  resubmission, // Represents when a document is sent back to the student for re-upload.
}

class Document {
  final String id;
  final String name;
  final String studentName;
  final String category;
  final DocumentStatus status; // This represents the final, overall status of the document.
  final String studentId;
  final DateTime uploadedDate;
  final String? url;

  // New fields for detailed AI and Faculty review feedback.
  final DocumentStatus? aiStatus;
  final String? aiComment;
  final DocumentStatus? facultyStatus;
  final String? facultyComment;
  final double? confidenceScore;

  // New field for the verification timeline.
  final List<TimelineEvent> timeline;

  // Legacy fields, which will be superseded by the new system but kept for compatibility.
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
    // Initialize new fields.
    this.aiStatus,
    this.aiComment,
    this.facultyStatus,
    this.facultyComment,
    this.confidenceScore,
    this.timeline = const [],
  });

  // Factory constructor to create a Document object from a Firestore snapshot.
  factory Document.fromFirestore(Map<String, dynamic> data, String documentId) {
    // Safely parse a timestamp from Firestore into a DateTime object.
    DateTime? safeTimestampParse(dynamic timestamp) {
      if (timestamp is Timestamp) {
        return timestamp.toDate();
      }
      return null;
    }

    // Safely parse a status string from Firestore into a DocumentStatus enum.
    DocumentStatus? parseStatus(String? statusString) {
      if (statusString == null) return null;
      try {
        return DocumentStatus.values.firstWhere((e) => e.name == statusString);
      } catch (e) {
        return null; // Return null if the string doesn't match any enum value.
      }
    }
    
    // Parse the list of timeline events from Firestore.
    final List<TimelineEvent> timelineEvents = (data['timeline'] as List<dynamic>?)
        ?.map((eventData) => TimelineEvent.fromMap(eventData as Map<String, dynamic>))
        .toList() ?? [];
    
    // Ensure the timeline is always sorted by date.
    timelineEvents.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return Document(
      id: documentId,
      name: data['doc_name'] ?? 'Untitled Document',
      studentName: data['uploader_name'] ?? 'Unknown Name',
      category: data['category'] ?? 'Uncategorized',
      status: parseStatus(data['status']) ?? DocumentStatus.pending,
      studentId: data['studentId'] ?? '',
      uploadedDate: safeTimestampParse(data['uploaded_at']) ?? DateTime.now(),
      url: data['doc_url'],
      
      // Assign new fields from Firestore data.
      aiStatus: parseStatus(data['ai_status']),
      aiComment: data['ai_comment'],
      facultyStatus: parseStatus(data['faculty_status']),
      facultyComment: data['faculty_comment'],
      confidenceScore: (data['confidence_score'] as num?)?.toDouble(),
      timeline: timelineEvents,

      // Assign legacy fields for backward compatibility.
      verifiedByUserId: data['verified_by_user_id'],
      verificationDate: safeTimestampParse(data['verification_date']),
      comments: data['comments'],
    );
  }

  // NEW: Converts the Document object into a Map for Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'doc_name': name,
      'uploader_name': studentName,
      'category': category,
      'status': status.name,
      'studentId': studentId,
      'uploaded_at': Timestamp.fromDate(uploadedDate),
      'doc_url': url,
      // Add the new fields to the map, ensuring they are null if not set.
      'ai_status': aiStatus?.name,
      'ai_comment': aiComment,
      'faculty_status': facultyStatus?.name,
      'faculty_comment': facultyComment,
      'confidence_score': confidenceScore,
      // Convert the timeline events back to a list of maps.
      'timeline': timeline.map((event) => event.toMap()).toList(),
      'verified_by_user_id': verifiedByUserId,
      'verification_date': verificationDate != null ? Timestamp.fromDate(verificationDate!) : null,
      'comments': comments,
    };
  }
}
