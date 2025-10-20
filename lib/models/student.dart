import 'package:cloud_firestore/cloud_firestore.dart';

class Student {
  final String id;
  final String email;
  final String name;
  final String role;
  final String year;
  final String section;
  final String studentId;
  final String? photoURL; // Add this for the avatar

  Student({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.year,
    required this.section,
    required this.studentId,
    this.photoURL,
  });

  factory Student.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Student(
      id: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? data['studentName'] ?? 'No Name',
      role: data['role'] ?? 'student',
      year: data['year'] ?? '',
      section: data['section'] ?? '',
      studentId: data['studentId'] ?? '',
      photoURL: data['photoURL'], // It might be null
    );
  }
}
