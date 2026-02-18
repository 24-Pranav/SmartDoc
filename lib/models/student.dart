class Student {
  final String id;
  final String email;
  final String name;
  final String role;
  final String year;
  final String section;
  final String studentId;
  final String? photoURL;

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

  factory Student.fromFirestore(Map<String, dynamic> data, String documentId) {
    return Student(
      id: documentId,
      email: data['email'] ?? '',
      name: data['name'] ?? 'No Name',
      role: data['role'] ?? 'student',
      year: data['year'] ?? '',
      section: data['section'] ?? '',
      studentId: data['id'] ?? '', // CORRECTED: Was 'studentId' which doesn't exist
      photoURL: data['photoURL'],
    );
  }
}
