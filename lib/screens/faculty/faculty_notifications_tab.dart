import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart_doc/models/notification.dart' as model;
import 'package:smart_doc/screens/faculty/send_notification_screen.dart';

class FacultyNotificationsTab extends StatefulWidget {
  const FacultyNotificationsTab({super.key});

  @override
  State<FacultyNotificationsTab> createState() =>
      _FacultyNotificationsTabState();
}

class _FacultyNotificationsTabState extends State<FacultyNotificationsTab> {
  late Stream<QuerySnapshot> _notificationStream;

  @override
  void initState() {
    super.initState();
    final facultyId = FirebaseAuth.instance.currentUser!.uid;
    _notificationStream = FirebaseFirestore.instance
        .collection('notifications')
        .where('senderId', isEqualTo: facultyId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: _notificationStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final notifications = snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return model.Notification.fromFirestore(data, doc.id);
          }).toList();

          if (notifications.isEmpty) {
            return const Center(
                child: Text('You have not sent any notifications yet.'));
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return Card(
                margin:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: ListTile(
                  title: Text(notification.title),
                  subtitle: Text(notification.message),
                  trailing: Text(
                    notification.timestamp.toDate().toString().substring(0, 10),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SendNotificationScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
