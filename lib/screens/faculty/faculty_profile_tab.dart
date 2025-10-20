import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_doc/models/faculty.dart';
import 'package:smart_doc/screens/role_selection_screen.dart';

class FacultyProfileTab extends StatefulWidget {
  const FacultyProfileTab({super.key});

  @override
  State<FacultyProfileTab> createState() => _FacultyProfileTabState();
}

class _FacultyProfileTabState extends State<FacultyProfileTab> {
  Faculty? _faculty;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFacultyData();
  }

  Future<void> _fetchFacultyData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('faculty').doc(user.uid).get();
        if (doc.exists) {
          setState(() {
            _faculty = Faculty.fromFirestore(doc);
          });
        }
      } catch (e) {
        // Handle error
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_faculty == null) {
      return const Center(child: Text('No profile data found.'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _signOut(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              // You can add a network image here if you have a photoURL
              child: const Icon(Icons.person, size: 50),
            ),
            const SizedBox(height: 16),
            Text(_faculty!.name, style: Theme.of(context).textTheme.headlineSmall),
            Text(_faculty!.email, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildInfoRow(Icons.work, 'Department', _faculty!.department),
                    _buildInfoRow(Icons.phone, 'Contact No', _faculty!.contactNumber),
                    _buildInfoRow(
                      Icons.verified_user,
                      'Verification',
                      _faculty!.isVerified ? 'Verified' : 'Not Verified',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).primaryColor),
          const SizedBox(width: 16),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const Spacer(),
          Text(value),
        ],
      ),
    );
  }
}
