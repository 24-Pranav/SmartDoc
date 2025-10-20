import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:smart_doc/models/faculty.dart';
import 'package:smart_doc/models/user.dart' as app_user;
import 'package:smart_doc/services/firebase_service.dart';

class AdminUsersTab extends StatefulWidget {
  const AdminUsersTab({super.key});

  @override
  State<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<AdminUsersTab> {
  final FirebaseService _firebaseService = FirebaseService();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          flexibleSpace: const Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TabBar(
                tabs: [
                  Tab(text: 'Students'),
                  Tab(text: 'Faculty'),
                ],
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildUserList(context, 'student'),
            _buildFacultyList(context),
          ],
        ),
      ),
    );
  }

  Widget _buildUserList(BuildContext context, String role) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firebaseService.getUsersByRole(role),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Something went wrong'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No users found.'));
        }

        final users = snapshot.data!.docs
            .map((doc) => app_user.User.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
            .toList();

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                title: Text(user.name ?? 'No Name'),
                subtitle: Text(user.email),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _confirmDeleteUser(context, user.id),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFacultyList(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firebaseService.getFaculty(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Something went wrong'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No faculty found.'));
        }

        final faculties = snapshot.data!.docs
            .map((doc) => Faculty.fromFirestore(doc))
            .toList();

        return ListView.builder(
          itemCount: faculties.length,
          itemBuilder: (context, index) {
            final faculty = faculties[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                title: Text(faculty.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(faculty.email),
                    Text(
                      'Status: \${faculty.isVerified ? "Verified" : "Pending"}',
                      style: TextStyle(
                        color: faculty.isVerified ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _confirmDeleteFaculty(context, faculty.id),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDeleteUser(BuildContext context, String userId) async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('Are you sure you want to delete this user? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _firebaseService.deleteUser(userId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User deleted successfully.')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete user: \$e')),
        );
      }
    }
  }

  Future<void> _confirmDeleteFaculty(BuildContext context, String facultyId) async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('Are you sure you want to delete this faculty member? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _firebaseService.deleteFaculty(facultyId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Faculty member deleted successfully.')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete faculty member: \$e')),
        );
      }
    }
  }
}
