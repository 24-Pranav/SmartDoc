
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:smart_doc/models/user.dart' as model;

class AdminVerificationTab extends StatefulWidget {
  const AdminVerificationTab({super.key});

  @override
  _AdminVerificationTabState createState() => _AdminVerificationTabState();
}

class _AdminVerificationTabState extends State<AdminVerificationTab> {

  Stream<QuerySnapshot> getUnverifiedFacultyStream() {
    return FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'faculty')
        .where('isVerified', isEqualTo: false)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
        stream: getUnverifiedFacultyStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading data. Have you created the Firestore index?'));
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
              final faculty = facultyDocs[index];
              final user = model.User.fromFirestore(faculty.data() as Map<String, dynamic>, faculty.id);

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
                          onPressed: () => _approveFaculty(context, user.id),
                        ),
                        IconButton(
                          tooltip: 'Deny',
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () => _confirmDenial(context, user.id, user.name ?? 'No Name'),
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
              if (user.department != null) Text('Department: ${user.department}'),
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
  
  Future<void> _approveFaculty(BuildContext context, String userId) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({'isVerified': true});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Faculty member approved.'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error approving faculty: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _denyFaculty(BuildContext context, String userId) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Faculty member denied and removed.'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error denying faculty: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _confirmDenial(BuildContext context, String userId, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deny Verification'),
        content: Text('Are you sure you want to deny and remove $name?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
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
}
