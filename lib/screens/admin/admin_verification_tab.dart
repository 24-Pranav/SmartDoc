import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:smart_doc/models/user.dart' as model;
import 'package:smart_doc/widgets/custom_app_bar.dart';

class AdminVerificationTab extends StatefulWidget {
  const AdminVerificationTab({super.key});

  @override
  _AdminVerificationTabState createState() => _AdminVerificationTabState();
}

class _AdminVerificationTabState extends State<AdminVerificationTab> {
  Stream<QuerySnapshot> getUnverifiedFacultyStream() {
    return FirebaseFirestore.instance
        .collection('faculty')
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Faculty Verification'),
      body: StreamBuilder<QuerySnapshot>(
        stream: getUnverifiedFacultyStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
                child: Text('Error loading data. Have you created the Firestore index?'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No pending verifications.'));
          }

          final facultyDocs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: facultyDocs.length,
            itemBuilder: (context, index) {
              final facultyDoc = facultyDocs[index];
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(facultyDoc.id)
                    .get(),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return const ListTile(title: Text('Loading user...'));
                  }

                  if (!userSnapshot.hasData ||
                      !userSnapshot.data!.exists ||
                      userSnapshot.data!.data() == null) {
                    return Card(
                      color: Colors.red.shade50,
                      margin:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: ListTile(
                        leading: const Icon(Icons.error, color: Colors.red),
                        title: const Text('Error: User Not Found'),
                        subtitle: Text(
                            'No matching user record for faculty ID: ${facultyDoc.id}'),
                        trailing: IconButton(
                          tooltip: 'Remove Orphaned Entry',
                          icon: const Icon(Icons.delete_forever, color: Colors.red),
                          onPressed: () =>
                              _confirmRemoveOrphaned(context, facultyDoc.id),
                        ),
                      ),
                    );
                  }

                  final user = model.User.fromFirestore(
                      userSnapshot.data!.data() as Map<String, dynamic>,
                      userSnapshot.data!.id);

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: GestureDetector(
                      onTap: () => _showUserDetails(context, user),
                      child: ListTile(
                        title: Text(user.name ?? 'No Name'),
                        subtitle: Text(user.email),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Approve',
                              icon: const Icon(Icons.check, color: Colors.green),
                              onPressed: () => _approveFaculty(context, user),
                            ),
                            IconButton(
                              tooltip: 'Deny',
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () => _confirmDenial(
                                  context, user.id, user.name ?? 'No Name'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  void _showUserDetails(BuildContext context, model.User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user.name ?? 'User Details'),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Text('Email: ${user.email}'),
              Text('Role: ${user.role}'),
              if (user.department != null)
                Text('Department: ${user.department}'),
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

  Future<void> _approveFaculty(BuildContext context, model.User user) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      final userRef = FirebaseFirestore.instance.collection('users').doc(user.id);
      batch.update(userRef, {'isVerified': true});

      final facultyRef = FirebaseFirestore.instance.collection('faculty').doc(user.id);
      batch.update(facultyRef, {'status': 'approved'});

      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Faculty member approved.'),
            backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error approving faculty: $e'),
            backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _denyFaculty(BuildContext context, String userId) async {
    try {
      final batch = FirebaseFirestore.instance.batch();

      final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
      final facultyRef = FirebaseFirestore.instance.collection('faculty').doc(userId);

      batch.delete(userRef);
      batch.delete(facultyRef);

      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Faculty member denied and removed.'),
            backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error denying faculty: $e'),
            backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _confirmDenial(
      BuildContext context, String userId, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deny Verification'),
        content: Text(
            'Are you sure you want to deny and remove $name? This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Deny', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _denyFaculty(context, userId);
    }
  }

  Future<void> _removeOrphanedFaculty(
      BuildContext context, String facultyId) async {
    try {
      await FirebaseFirestore.instance
          .collection('faculty')
          .doc(facultyId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Orphaned faculty entry removed.'),
            backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error removing entry: $e'),
            backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _confirmRemoveOrphaned(
      BuildContext context, String facultyId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Orphaned Entry'),
        content: const Text(
            'Are you sure you want to remove this orphaned faculty record? This can happen if a user is deleted, but their verification request remains.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _removeOrphanedFaculty(context, facultyId);
    }
  }
}
