import 'package:cloud_firestore/cloud_firestore.dart';

class Faculty {
  final String id;
  final String name;
  final String email;
  final String department;
  final String contactNumber;
  final bool isVerified;

  Faculty({
    required this.id,
    required this.name,
    required this.email,
    required this.department,
    required this.contactNumber,
    required this.isVerified,
  });

  factory Faculty.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Faculty(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      department: data['department'] ?? '',
      contactNumber: data['contactNumber'] ?? '',
      isVerified: data['isVerified'] ?? false,
    );
  }
}
