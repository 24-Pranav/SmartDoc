
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:smart_doc/models/document.dart';
import 'package:smart_doc/services/supabase_service.dart';
import 'package:smart_doc/utils/show_message_box.dart';
import 'package:smart_doc/widgets/status_badge.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class StudentHomeTab extends StatefulWidget {
  const StudentHomeTab({super.key});

  @override
  State<StudentHomeTab> createState() => _StudentHomeTabState();
}

class _StudentHomeTabState extends State<StudentHomeTab> {
  bool _isLoading = false;
  final SupabaseService _supabaseService = SupabaseService();

  // REVISED: Combines the document viewer with the new feedback and timeline sections.
  void _showDocumentDialog(BuildContext context, Document doc) {
    if (doc.url == null || doc.url!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document not available.')),
      );
      return;
    }

    final isPdf = doc.url!.toLowerCase().endsWith('.pdf');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          // Use a constrained box to control the dialog's max height and allow scrolling.
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                // This Expanded widget makes the content area scrollable.
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 1. The Document Viewer (Image or PDF)
                        SizedBox(
                          // Set a reasonable height for the viewer.
                          height: MediaQuery.of(context).size.height * 0.4,
                          child: isPdf
                              ? SfPdfViewer.network(doc.url!)
                              : InteractiveViewer(
                                  panEnabled: true,
                                  boundaryMargin: const EdgeInsets.all(20),
                                  minScale: 0.5,
                                  maxScale: 4,
                                  child: Image.network(doc.url!, fit: BoxFit.contain),
                                ),
                        ),
                        const Divider(),
                        // 2. The Feedback and Timeline Section
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (doc.aiComment != null && doc.aiComment!.isNotEmpty)
                                _buildCommentSection(
                                  title: "AI Verification",
                                  comment: doc.aiComment!,
                                  status: doc.aiStatus,
                                ),
                              if (doc.facultyComment != null && doc.facultyComment!.isNotEmpty)
                                _buildCommentSection(
                                  title: "Faculty Review",
                                  comment: doc.facultyComment!,
                                  status: doc.facultyStatus,
                                ),
                              const SizedBox(height: 16),
                              const Text("Verification Timeline",
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              VerificationTimeline(timeline: doc.timeline),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  // Helper widget to build the comment sections for AI and Faculty.
  Widget _buildCommentSection({required String title, required String comment, DocumentStatus? status}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              if (status != null) StatusBadge(status: status), // Shows a status chip (e.g., Rejected)
            ],
          ),
          const SizedBox(height: 4),
          Text(comment, style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  // ... (rest of the code remains the same)

  Widget _getLeadingIcon(String? url) {
    if (url == null || url.isEmpty) {
      return const Icon(Icons.article_outlined, size: 40);
    }

    final lowercasedUrl = url.toLowerCase();
    if (lowercasedUrl.endsWith('.jpg') || lowercasedUrl.endsWith('.jpeg') || lowercasedUrl.endsWith('.png')) {
      return SizedBox(
        width: 50,
        height: 50,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: Image.network(
            url,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const Center(child: CircularProgressIndicator());
            },
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.image, color: Colors.red);
            },
          ),
        ),
      );
    } else if (lowercasedUrl.endsWith('.pdf')) {
      return const Icon(Icons.picture_as_pdf, size: 40, color: Colors.red);
    } else {
      return const Icon(Icons.article_outlined, size: 40);
    }
  }

  Future<void> _deleteDocument(String docId, String url) async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document'),
        content: const Text('Are you sure you want to delete this document?'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: const Text('Delete'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('documents').doc(docId).delete();
      await _supabaseService.deleteFile(url);
      if (mounted) {
        showMessageBox(context, 'Success', 'Document deleted successfully.');
      }
    } catch (e) {
      if (mounted) {
        showMessageBox(context, 'Error', 'Failed to delete document: $e');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text('Please log in.'));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Documents')),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('documents')
                      .where('studentId', isEqualTo: user.uid)
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
                          child: Text('You haven\'t uploaded any documents yet.', textAlign: TextAlign.center),
                        ),
                      );
                    }

                    final documents = snapshot.data!.docs.map((doc) {
                      return Document.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
                    }).toList();

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      itemCount: documents.length,
                      itemBuilder: (context, index) {
                        final doc = documents[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                            leading: _getLeadingIcon(doc.url),
                            title: Text(doc.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Category: ${doc.category}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                StatusBadge(status: doc.status),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteDocument(doc.id, doc.url!),
                                ),
                              ],
                            ),
                            onTap: () => _showDocumentDialog(context, doc),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}

// A new, reusable widget to display the verification timeline.
class VerificationTimeline extends StatelessWidget {
  final List<TimelineEvent> timeline;

  const VerificationTimeline({super.key, required this.timeline});

  @override
  Widget build(BuildContext context) {
    // If the timeline is empty, show a message indicating the process has just started.
    if (timeline.isEmpty) {
      return const Text("Document uploaded. Pending initial review.");
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(), // The timeline is inside a scrollable dialog.
      itemCount: timeline.length,
      itemBuilder: (context, index) {
        final event = timeline[index];
        final isLastEvent = index == timeline.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // The vertical line and icon for the timeline.
            Column(
              children: [
                Icon(
                  isLastEvent ? Icons.check_circle : Icons.radio_button_checked,
                  color: isLastEvent ? Colors.green : Colors.blue,
                  size: 20,
                ),
                if (!isLastEvent)
                  Container(
                    width: 2,
                    height: 40,
                    color: Colors.blue,
                  ),
              ],
            ),
            const SizedBox(width: 12),
            // The details of the timeline event.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.status, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(DateFormat.yMMMd().add_jm().format(event.timestamp), style: const TextStyle(color: Colors.grey)),
                  if (event.comment != null && event.comment!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(event.comment!, style: const TextStyle(fontStyle: FontStyle.italic)),
                    ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
