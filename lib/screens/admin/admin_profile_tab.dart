import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smart_doc/screens/role_selection_screen.dart';

class AdminProfileTab extends StatelessWidget {
  const AdminProfileTab({super.key});

  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    // Navigate to the role selection screen and remove all previous routes.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Profile'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const CircleAvatar(
              radius: 50,
              child: Icon(Icons.admin_panel_settings, size: 50),
            ),
            const SizedBox(height: 20),
            Text(
              'Admin',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 10),
            if (user != null)
              Text(
                user.email ?? 'admin@example.com',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              icon: const Icon(Icons.logout), 
              label: const Text('Sign Out'),
              onPressed: () => _signOut(context),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
