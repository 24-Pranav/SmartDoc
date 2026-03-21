import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_doc/models/document.dart';
import 'package:smart_doc/models/user.dart' as model;
import 'package:smart_doc/widgets/status_badge.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart_doc/models/notification.dart' as notification_model;


class StudentDocumentsScreen extends StatefulWidget {
  final model.User student;

  const StudentDocumentsScreen({super.key, required this.student});

  @override
  State<StudentDocumentsScreen> createState() => _StudentDocumentsScreenState();
}

class _StudentDocumentsScreenState extends State<StudentDocumentsScreen> {
  bool _isDownloading = false;

  Future<void> _downloadFile(BuildContext context, String? url, String docName) async {
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document URL is not available.')),
      );
      return;
    }

    setState(() {
      _isDownloading = true;
    });

    try {
      final directory = await getExternalStorageDirectory();
      if (directory == null) {
        throw Exception('Could not get storage directory.');
      }
      final filePath = '${directory.path}/$docName';

      await Dio().download(url, filePath);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Downloaded to $filePath')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download failed: $e')),
      );
    } finally {
      setState(() {
        _isDownloading = false;
      });
    }
  }

  void _showDocumentDialog(BuildContext context, Document doc) {
    final url = doc.url;
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document not available.')),
      );
      return;
    }

    final isPdf = url.toLowerCase().endsWith('.pdf');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        doc.name,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    _isDownloading
                        ? const CircularProgressIndicator()
                        : IconButton(
                      icon: const Icon(Icons.download_for_offline),
                      onPressed: () => _downloadFile(context, url, doc.name),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: isPdf
                    ? SfPdfViewer.network(url)
                    : InteractiveViewer(
                  panEnabled: true,
                  boundaryMargin: const EdgeInsets.all(20),
                  minScale: 0.5,
                  maxScale: 4,
                  child: Image.network(url, fit: BoxFit.contain),
                ),
              ),
              const Divider(height: 1),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCommunicationHistory(BuildContext context) {
    final facultyId = FirebaseAuth.instance.currentUser?.uid;
    if (facultyId == null) {
      // Handle case where faculty is not logged in
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Communication History'),
          content: SizedBox(
            width: double.maxFinite,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('notifications')
                  .where('target', isEqualTo: widget.student.id)
                  .where('senderId', isEqualTo: facultyId)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Text('No communication history found.');
                }

                final notifications = snapshot.data!.docs.map((doc) {
                  return notification_model.Notification.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
                }).toList();

                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    final timestamp = notification.timestamp as Timestamp;
                    return ListTile(
                      title: Text(notification.title),
                      subtitle: Text(notification.message),
                      trailing: Text(TimeAgo.timeAgoSinceDate(timestamp.toDate())),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.student.name ?? 'Student'}'s Documents"),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Communication History',
            onPressed: () => _showCommunicationHistory(context),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('documents')
            .where('studentId', isEqualTo: widget.student.id) // Querying with the old field name
            .orderBy('uploaded_at', descending: true) // Sorting with the old field name
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            // Prompt to create an index for the old field names.
            return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                      'Error: ${snapshot.error}\n\nFirestore needs an index for this query. Please create a composite index for the documents collection with studentId (ascending) and uploaded_at (descending).',
                      textAlign: TextAlign.center),
                ));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('This student has not uploaded any documents.'));
          }

          final documents = snapshot.data!.docs.map((doc) {
            return Document.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
          }).toList();

          return ListView.builder(
            itemCount: documents.length,
            itemBuilder: (context, index) {
              final doc = documents[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  title: Text(doc.name),
                  subtitle: Text(doc.category),
                  trailing: StatusBadge(status: doc.status),
                  onTap: () => _showDocumentDialog(context, doc),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class TimeAgo {
  static String timeAgoSinceDate(DateTime date, {bool numericDates = true}) {
    final date2 = DateTime.now();
    final difference = date2.difference(date);

    if (difference.inSeconds < 5) {
      return 'Just now';
    } else if (difference.inSeconds < 60) {
      return '${difference.inSeconds} seconds ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return (numericDates) ? '1 day ago' : 'Yesterday';
    } else {
      return '${difference.inDays} days ago';
    }
  }
}
