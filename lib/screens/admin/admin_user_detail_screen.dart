
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// Represents a single document from Firestore
class Document {
  final String id;
  final String fileName;
  final String fileUrl;
  final Timestamp timestamp;

  Document({required this.id, required this.fileName, required this.fileUrl, required this.timestamp});

  factory Document.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Document(
      id: doc.id,
      fileName: data['fileName'] ?? 'Unnamed File',
      fileUrl: data['fileUrl'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(),
    );
  }
}

class AdminUserDetailScreen extends StatelessWidget {
  final String userId;
  final String userName;

  const AdminUserDetailScreen({super.key, required this.userId, required this.userName});

  // Function to open the document URL
  void _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      // Could show a snackbar here with an error
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("$userName's Documents"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Query the 'documents' collection for docs matching the userId
        stream: FirebaseFirestore.instance
            .collection('documents')
            .where('userId', isEqualTo: userId)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading documents.'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'This user has not uploaded any documents.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final documents = snapshot.data!.docs.map((doc) => Document.fromFirestore(doc)).toList();

          return ListView.builder(
            itemCount: documents.length,
            itemBuilder: (context, index) {
              final doc = documents[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: const Icon(Icons.description),
                  title: Text(doc.fileName),
                  subtitle: Text('Uploaded on: ${doc.timestamp.toDate().toLocal()}'),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () {
                    if (doc.fileUrl.isNotEmpty) {
                      _launchURL(doc.fileUrl);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('File URL is not available.')),
                      );
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
