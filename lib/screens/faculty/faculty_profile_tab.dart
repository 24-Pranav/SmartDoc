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
    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('faculty').doc(user.uid).get();
        if (doc.exists && mounted) {
          setState(() {
            _faculty = Faculty.fromFirestore(doc);
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error fetching profile: ${e.toString()}'))
          );
        }
      }
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: ${e.toString()}'))
      );
    }
  }

 @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        backgroundColor: const Color(0xFF2C3E50), // Dark blue-grey
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _faculty == null
              ? _buildErrorState(context)
              : _buildProfileContent(context, _faculty!, theme),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Could not load faculty profile.'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _signOut(context),
              child: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context, Faculty faculty, ThemeData theme) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildProfileHeader(context, faculty, theme),
            const SizedBox(height: 32),
            _buildDetailsCard(context, faculty, theme),
            const SizedBox(height: 32),
            _buildLogoutButton(context, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, Faculty faculty, ThemeData theme) {
    return Column(
      children: [
        const CircleAvatar(
          radius: 50,
          backgroundColor: Colors.white,
          child: Icon(Icons.person, size: 60, color: Color(0xFF2C3E50)),
        ),
        const SizedBox(height: 16),
        Text(
          faculty.name,
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          faculty.email,
          style: theme.textTheme.bodyLarge?.copyWith(color: Colors.blueAccent),
        ),
      ],
    );
  }

  Widget _buildDetailsCard(BuildContext context, Faculty faculty, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
          child: Text(
            'Details',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        Card(
          elevation: 1,
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildInfoRow(theme, Icons.work_outline, 'Department', faculty.department),
                const Divider(height: 24),
                _buildInfoRow(theme, Icons.phone_outlined, 'Contact No', faculty.contactNumber),
                const Divider(height: 24),
                _buildInfoRow(
                  theme,
                  Icons.verified_user_outlined,
                  'Verification',
                  faculty.isVerified ? 'Verified' : 'Not Verified',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(ThemeData theme, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary.withOpacity(0.8)),
          const SizedBox(width: 16),
          Text(label, style: theme.textTheme.bodyLarge),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.secondary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, ThemeData theme) {
    return ElevatedButton.icon(
      onPressed: () => _signOut(context),
      icon: const Icon(Icons.logout, size: 20),
      label: const Text('Logout'),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: const Color(0xFF3498DB), // Blue color
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        textStyle: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}
