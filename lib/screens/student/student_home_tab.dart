import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart_doc/models/document.dart';
import 'package:smart_doc/services/supabase_service.dart';
import 'package:smart_doc/utils/show_message_box.dart';
import 'package:smart_doc/widgets/status_badge.dart';

class StudentHomeTab extends StatefulWidget {
  const StudentHomeTab({super.key});

  @override
  State<StudentHomeTab> createState() => _StudentHomeTabState();
}

class _StudentHomeTabState extends State<StudentHomeTab> {
  bool _isLoading = false;
  // Instantiate the service to use its methods
  final SupabaseService _supabaseService = SupabaseService();

  void _showDocumentDialog(BuildContext context, Document doc) {
    if (doc.url == null || doc.url!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document not available.')),
      );
      return;
    }

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
                child: Text(
                  doc.name,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              const Divider(height: 1),
              InteractiveViewer(
                panEnabled: true,
                boundaryMargin: const EdgeInsets.all(20),
                minScale: 0.5,
                maxScale: 4,
                child: Image.network(
                  doc.url!,
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
      // Delete from Firestore
      await FirebaseFirestore.instance.collection('documents').doc(docId).delete();

      // Refactored to use the SupabaseService for deletion
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
