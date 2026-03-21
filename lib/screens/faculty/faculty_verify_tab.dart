import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart_doc/models/document.dart';
import 'package:smart_doc/models/user.dart' as model;
import 'package:smart_doc/utils/show_message_box.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:smart_doc/extensions/string_extension.dart';

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
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(doc.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
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
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showStudentDetails(BuildContext context, String studentId) async {
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(studentId).get();
      if (!userDoc.exists || userDoc.data() == null) {
        if (mounted) showMessageBox(context, 'Not Found', 'Could not find details for this student.');
        return;
      }
      final student = model.User.fromFirestore(userDoc.data()!, userDoc.id);
      if (mounted) {
        showMessageBox(context, 'Student Details', 'Name: ${student.name}\nEmail: ${student.email}');
      }
    } catch (e) {
      if (mounted) showMessageBox(context, 'Error', 'Failed to fetch student details: $e');
    }
  }


  Future<void> _showReviewDialog(BuildContext context, Document document, DocumentStatus newStatus) async {
    final commentController = TextEditingController();
    final actionText = newStatus.name.capitalize();

    final bool? submit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$actionText Document'),
        content: TextField(
          controller: commentController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Comment (Optional)',
            hintText: 'Provide feedback for the student...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Submit $actionText'),
          ),
        ],
      ),
    );

    if (submit == true) {
      if (mounted) {
        _updateDocumentStatus(document, newStatus, commentController.text.trim());
      }
    }
  }

  Future<void> _updateDocumentStatus(Document document, DocumentStatus newStatus, String comment) async {
    final facultyUser = FirebaseAuth.instance.currentUser;
    if (facultyUser == null) {
      if (mounted) showMessageBox(context, 'Error', 'You must be logged in.');
      return;
    }

    try {
      final docRef = FirebaseFirestore.instance.collection('documents').doc(document.id);
      
      final newTimelineEvent = TimelineEvent(
        status: "Faculty Review - ${newStatus.name.capitalize()}",
        timestamp: DateTime.now(),
        comment: comment,
      );

      await docRef.set({
        'status': newStatus.name,
        'faculty_status': newStatus.name,
        'faculty_comment': comment,
        'verified_by_user_id': facultyUser.uid,
        'verification_date': FieldValue.serverTimestamp(),
        'timeline': FieldValue.arrayUnion([newTimelineEvent.toMap()]),
      }, SetOptions(merge: true));

      if (mounted) {
        showMessageBox(context, 'Success', 'Document has been ${newStatus.name}.');
      }
    } catch (e) {
      if (mounted) {
        showMessageBox(context, 'Error', 'Failed to update status: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Documents'), centerTitle: true),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('documents')
            .where('status', whereIn: ['pending', 'resubmission'])
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
            return const Center(child: Text('No documents to verify.'));
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
                            const Icon(Icons.info_outline, size: 16)
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
                          if (document.aiStatus != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('AI Verification:', style: TextStyle(fontWeight: FontWeight.bold)),
                                  Text('Status: ${document.aiStatus!.name.capitalize()}'),
                                  if (document.aiComment != null && document.aiComment!.isNotEmpty)
                                    Text('Comment: ${document.aiComment}'),
                                ],
                              ),
                            ),
                          Center(
                            child: FilledButton.tonal(
                              onPressed: () => _showDocumentDialog(context, document),
                              child: const Text('View Document'),
                            ),
                          ),
                          const Divider(height: 20),
                          // **FIX: Replaced Row with Wrap to prevent overflow**
                          Wrap(
                            alignment: WrapAlignment.spaceEvenly,
                            spacing: 8.0, // Horizontal space between buttons
                            runSpacing: 8.0, // Vertical space if buttons wrap
                            children: [
                              ElevatedButton.icon(
                                icon: const Icon(Icons.check_circle_outline),
                                label: const Text('Approve'),
                                onPressed: () => _showReviewDialog(context, document, DocumentStatus.approved),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                              ),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.history, size: 18),
                                label: const Text('Resubmit'),
                                onPressed: () => _showReviewDialog(context, document, DocumentStatus.resubmission),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                              ),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.cancel_outlined),
                                label: const Text('Reject'),
                                onPressed: () => _showReviewDialog(context, document, DocumentStatus.rejected),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
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
