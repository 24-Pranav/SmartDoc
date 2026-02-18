
class User {
  final String id;
  final String email;
  final String? name;
  final String role;
  final String? department;
  final bool? isVerified;

  User({
    required this.id,
    required this.email,
    this.name,
    required this.role,
    this.department,
    this.isVerified,
  });

  factory User.fromFirestore(Map<String, dynamic> data, String documentId) {
    return User(
      id: documentId,
      email: data['email'] ?? '',
      name: data['name'] as String?,
      role: data['role'] ?? '',
      department: data['department'] as String?,
      isVerified: data['isVerified'] as bool?,
    );
  }
}
