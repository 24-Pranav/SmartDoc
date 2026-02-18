import 'dart:convert';

class Document {
  final String id;
  final String filePath;
  final DateTime createdAt;

  Document({
    required this.id,
    required this.filePath,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'filePath': filePath,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Document.fromMap(Map<String, dynamic> map) {
    return Document(
      id: map['id'],
      filePath: map['filePath'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  String toJson() => json.encode(toMap());

  factory Document.fromJson(String source) => Document.fromMap(json.decode(source));
}
