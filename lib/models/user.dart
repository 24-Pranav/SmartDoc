
class User {
  final String id;
  final String email;
  final String? name;
  final String role;

  User({
    required this.id,
    required this.email,
    this.name,
    required this.role,
  });

  factory User.fromFirestore(Map<String, dynamic> data, String documentId) {
    return User(
      id: documentId,
      email: data['email'] ?? '',
      name: data['name'] as String?,
      role: data['role'] ?? '',
    );
  }
}
