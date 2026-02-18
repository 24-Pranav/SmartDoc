
import 'package:cloud_firestore/cloud_firestore.dart';

class Notification {
  final String id;
  final String title;
  final String message;
  final String senderId;
  final String senderName;
  final String target;
  final Timestamp timestamp;
  final List<String> dismissedBy; // ADDED: List to track dismissals

  Notification({
    required this.id,
    required this.title,
    required this.message,
    required this.senderId,
    required this.senderName,
    required this.target,
    required this.timestamp,
    required this.dismissedBy, // ADDED: to constructor
  });

  factory Notification.fromFirestore(Map<String, dynamic> data, String id) {
    // Handles the 'dismissedBy' field, ensuring it's always a list
    final dismissedByData = data['dismissedBy'];
    final List<String> dismissedByList = dismissedByData is List
        ? List<String>.from(dismissedByData.map((item) => item.toString()))
        : [];

    return Notification(
      id: id,
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? 'N/A',
      target: data['target'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(),
      dismissedBy: dismissedByList, // ADDED: with safe parsing
    );
  }
}
