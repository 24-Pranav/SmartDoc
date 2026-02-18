import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart_doc/models/document.dart';
import 'package:smart_doc/models/user.dart' as model;
import 'package:smart_doc/utils/show_message_box.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class FacultyVerifyTab extends StatefulWidget {
  const FacultyVerifyTab({super.key});

  @override
  State<FacultyVerifyTab> createState() => _FacultyVerifyTabState();
}

class _FacultyVerifyTabState extends State<FacultyVerifyTab> {

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
      // Make the dialog larger to better fit documents
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  doc.name,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              const Divider(height: 1),
              // Use a flexible container for the viewer
              Flexible(
                child: isPdf
                    ? SfPdfViewer.network(url)
                    // Use InteractiveViewer for images to allow zoom/pan
                    : InteractiveViewer(
                        panEnabled: true,
                        boundaryMargin: const EdgeInsets.all(20),
                        minScale: 0.5,
                        maxScale: 4,
                        child: Image.network(
                          url,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Padding(
                              padding: EdgeInsets.all(32.0),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return const Padding(
                              padding: EdgeInsets.all(32.0),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.error, color: Colors.red, size: 50),
                                    SizedBox(height: 8),
                                    Text('Could not load document'),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
              const Divider(height: 1),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Close'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showStudentDetails(BuildContext context, String studentId) async {
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(studentId).get();
      if (!userDoc.exists) {
        if (mounted) showMessageBox(context, 'Error', 'Student details not found.');
        return;
      }
      final student = model.User.fromFirestore(userDoc.data()!, userDoc.id);

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(student.name ?? 'Student Details'),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text('Email: ${student.email}'),
                  Text('Role: ${student.role}'),
                  if (student.department != null) Text('Department: ${student.department}'),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Close'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) showMessageBox(context, 'Error', 'Failed to get student details: $e');
    }
  }

  Future<void> _updateDocumentStatus(Document document, String newStatus) async {
    try {
      final facultyUser = FirebaseAuth.instance.currentUser;
      if (facultyUser == null) {
        if (mounted) showMessageBox(context, 'Error', 'You must be logged in.');
        return;
      }

      final docRef = FirebaseFirestore.instance.collection('documents').doc(document.id);

      await docRef.update({
        'status': newStatus,
        'verified_by_user_id': facultyUser.uid,
        'verification_date': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        showMessageBox(context, 'Success', 'Document has been ${newStatus == 'approved' ? 'Approved' : 'Rejected'}.');
      }
    } catch (e) {
      if (mounted) showMessageBox(context, 'Error', 'Failed to update status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Documents'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('documents')
            .where('status', isEqualTo: 'pending')
            .orderBy('uploaded_at', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('No documents to verify.'),
              ),
            );
          }

          final documents = snapshot.data!.docs.map((doc) {
            return Document.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
          }).toList();

          return ListView.builder(
            itemCount: documents.length,
            itemBuilder: (context, index) {
              final document = documents[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ExpansionTile(
                  leading: const Icon(Icons.pending_actions, size: 40),
                  title: Text(document.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => _showStudentDetails(context, document.studentId),
                        child: Row(
                          children: [
                            Text('Student: ${document.studentName}'),
                            const SizedBox(width: 8),
                            const Icon(Icons.info_outline, size: 16),
                          ],
                        ),
                      ),
                      Text('Category: ${document.category}'),
                    ],
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Uploaded: ${document.uploadedDate.toLocal().toString().substring(0, 16)}'),
                          const SizedBox(height: 16),
                          Center(
                            child: FilledButton.tonal(
                              onPressed: () => _showDocumentDialog(context, document),
                              child: const Text('View Document'),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Divider(),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton.icon(
                                icon: const Icon(Icons.check_circle_outline),
                                label: const Text('Approve'),
                                onPressed: () => _updateDocumentStatus(document, 'approved'),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                              ),
                              TextButton.icon(
                                icon: const Icon(Icons.cancel_outlined),
                                label: const Text('Reject'),
                                onPressed: () => _updateDocumentStatus(document, 'rejected'),
                                style: TextButton.styleFrom(foregroundColor: Colors.red),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
