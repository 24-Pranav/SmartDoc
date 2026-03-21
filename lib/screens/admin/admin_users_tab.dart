import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_doc/models/user.dart' as model;
import 'package:smart_doc/widgets/custom_app_bar.dart';

class AdminUsersTab extends StatefulWidget {
  const AdminUsersTab({super.key});

  @override
  _AdminUsersTabState createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<AdminUsersTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Manage Users'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Students'),
              Tab(text: 'Faculty'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildUserList('student'),
                _buildFacultyList(), // **FIX: Use a dedicated builder for faculty**
              ],
            ),
          ),
        ],
      ),
    );
  }

  // **FIX: A new, dedicated widget to build the faculty list**
  Widget _buildFacultyList() {
    return StreamBuilder<QuerySnapshot>(
      // **FIX: Query the 'faculty' collection for approved members**
      stream: FirebaseFirestore.instance
          .collection('faculty')
          .where('status', isEqualTo: 'approved')
          .snapshots(),
      builder: (context, facultySnapshot) {
        if (facultySnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (facultySnapshot.hasError) {
          return const Center(child: Text('Error loading faculty data.'));
        }
        if (!facultySnapshot.hasData || facultySnapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No approved faculty found.'));
        }

        final facultyDocs = facultySnapshot.data!.docs;

        // **FIX: Fetch user data for each approved faculty member**
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
                  return const ListTile(title: Text('Loading...'));
                }
                if (userSnapshot.hasError || !userSnapshot.hasData || !userSnapshot.data!.exists) {
                  return const ListTile(
                    title: Text('Error: User data not found', style: TextStyle(color: Colors.red)),
                  );
                }

                final user = model.User.fromFirestore(
                    userSnapshot.data!.data() as Map<String, dynamic>, userSnapshot.data!.id);

                // Apply search filter
                if (_searchQuery.isNotEmpty && !(user.name?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)) {
                  return const SizedBox.shrink(); // Hide if not matching search
                }

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  elevation: 3,
                  child: ListTile(
                    leading: const CircleAvatar(child: Text('F')),
                    title: Text(user.name ?? 'No Name', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${user.email}\nRole: Faculty'),
                    isThreeLine: true,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      tooltip: 'Delete User',
                      onPressed: () => _confirmDelete(context, user),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildUserList(String role) {
    Query query = FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: role)
        .orderBy('name');

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No ${role}s found.'));
        }

        var users = snapshot.data!.docs.map((doc) {
          return model.User.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
        }).toList();

        if (_searchQuery.isNotEmpty) {
          users = users.where((user) {
            return user.name?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false;
          }).toList();
        }

        if (users.isEmpty) {
          return Center(child: Text('No users found matching "$_searchQuery".'));
        }

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              elevation: 3,
              child: GestureDetector(
                onTap: () => _showUserDetails(context, user),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(user.role.substring(0, 1).toUpperCase()),
                  ),
                  title: Text(user.name ?? 'No Name Provided', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${user.email}\nRole: ${user.role}'),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    tooltip: 'Delete User',
                    onPressed: () => _confirmDelete(context, user),
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


  Future<void> _confirmDelete(BuildContext context, model.User user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text('Are you sure you want to permanently delete the user ${user.name}? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteUser(context, user);
    }
  }

  Future<void> _deleteUser(BuildContext context, model.User user) async {
    try {
      final batch = FirebaseFirestore.instance.batch();

      // **FIX: Delete from both 'users' and 'faculty' collections if the user is a faculty member**
      final userRef = FirebaseFirestore.instance.collection('users').doc(user.id);
      batch.delete(userRef);

      if (user.role == 'faculty') {
        final facultyRef = FirebaseFirestore.instance.collection('faculty').doc(user.id);
        batch.delete(facultyRef);
      }

      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User permanently deleted.'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting user: $e'), backgroundColor: Colors.red),
      );
    }
  }
}
