import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:smart_doc/models/document.dart';
import 'package:smart_doc/models/user.dart' as model;
import 'package:smart_doc/screens/student/document_detail_screen.dart';

class AdminUserDetailScreen extends StatelessWidget {
  final model.User user;

  const AdminUserDetailScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${user.name ?? 'User'}'s Documents"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('documents')
            .where('studentId', isEqualTo: user.id)
            .orderBy('uploaded_at', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading documents. Please ensure Firestore indexes are configured.'));
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

          final documents = snapshot.data!.docs
              .map((doc) => Document.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
              .toList();

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: documents.length,
            itemBuilder: (context, index) {
              final doc = documents[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: Icon(Icons.description_outlined, color: Theme.of(context).primaryColor),
                  title: Text(doc.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Category: ${doc.category}'),
                  trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey.shade600),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DocumentDetailScreen(document: doc),
                      ),
                    );
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
