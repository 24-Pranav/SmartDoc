import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_doc/screens/role_selection_screen.dart';
import 'package:smart_doc/screens/admin/admin_dashboard_screen.dart';
import 'package:smart_doc/screens/faculty/faculty_dashboard_screen.dart';
import 'package:smart_doc/screens/student/student_dashboard_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text('Something went wrong. Please restart the app.')),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          // User is logged in, check their role.
          return FutureBuilder<List<DocumentSnapshot>>(
            future: Future.wait([
              FirebaseFirestore.instance.collection('users').doc(snapshot.data!.uid).get(),
              FirebaseFirestore.instance.collection('faculty').doc(snapshot.data!.uid).get(),
            ]),
            builder: (context, AsyncSnapshot<List<DocumentSnapshot>> snapshots) {
              if (snapshots.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              // Add robust error handling
              if (snapshots.hasError) {
                return Scaffold(
                  body: Center(
                    child: Text('Error checking user role: ${snapshots.error}'),
                  ),
                );
              }
              
              if (!snapshots.hasData) {
                  return const RoleSelectionScreen();
              }

              final userSnapshot = snapshots.data![0];
              final facultySnapshot = snapshots.data![1];

              if (userSnapshot.exists && userSnapshot.data() != null) {
                final userData = userSnapshot.data() as Map<String, dynamic>;
                if (userData['role'] == 'admin') {
                  return const AdminDashboardScreen();
                } 
              }

              if (facultySnapshot.exists) {
                return const FacultyDashboardScreen();
              } else if (userSnapshot.exists) {
                return const StudentDashboardScreen();
              } else {
                // If the user is authenticated but has no role document,
                // send them to role selection.
                return const RoleSelectionScreen();
              }
            },
          );
        } else {
          // User is not logged in
          return const RoleSelectionScreen();
        }
      },
    );
  }
}
