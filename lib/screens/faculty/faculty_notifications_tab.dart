
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
    // Ensure user is logged in before accessing UID
    if (FirebaseAuth.instance.currentUser != null) {
      final facultyId = FirebaseAuth.instance.currentUser!.uid;
      _notificationStream = FirebaseFirestore.instance
          .collection('notifications')
          .where('senderId', isEqualTo: facultyId)
          .orderBy('timestamp', descending: true)
          .snapshots();
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    // Added mounted check for safety
    if (!mounted) return;
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification deleted')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting notification: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Handle case where user is not logged in
    if (FirebaseAuth.instance.currentUser == null) {
      return const Center(child: Text('Please log in to see notifications.'));
    }

    return Scaffold(
      // ADDED: AppBar for better UI consistency
      appBar: AppBar(
        title: const Text('Sent Notifications'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _notificationStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
                child: Text('You have not sent any notifications yet.'));
          }

          final notifications = snapshot.data!.docs.map((doc) {
            return model.Notification.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
          }).toList();

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return Dismissible(
                key: Key(notification.id), 
                direction: DismissDirection.endToStart,
                onDismissed: (direction) {
                  _deleteNotification(notification.id);
                },
                background: Container(
                  color: Colors.red,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  alignment: Alignment.centerRight,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                child: Card(
                  margin:
                      const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  child: ListTile(
                    title: Text(notification.title),
                    subtitle: Text(notification.message),
                    trailing: Text(
                      notification.timestamp.toDate().toString().substring(0, 10),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      // ADDED: FloatingActionButton to navigate to the SendNotificationScreen
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SendNotificationScreen(),
            ),
          );
        },
        tooltip: 'Send Notification',
        child: const Icon(Icons.add),
      ),
    );
  }
}
