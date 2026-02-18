
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_doc/models/user.dart' as model;

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
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _searchController.clear();
        setState(() {
          _searchQuery = '';
        });
      }
    });
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
    return Column(
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
              _buildUserList('faculty'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUserList(String role) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: role)
          .orderBy('name')
          .snapshots(),
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
        
        users = users.where((user) => user.role != 'admin').toList();

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
      _deleteUser(context, user.id);
    }
  }

  Future<void> _deleteUser(BuildContext context, String userId) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User deleted from database.'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting user: $e'), backgroundColor: Colors.red),
      );
    }
  }
}
