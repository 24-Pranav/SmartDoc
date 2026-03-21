import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_doc/screens/role_selection_screen.dart';
import 'package:smart_doc/screens/admin/admin_dashboard_screen.dart';
import 'package:smart_doc/screens/faculty/faculty_dashboard_screen.dart';
import 'package:smart_doc/screens/student/student_dashboard_screen.dart';
import 'package:smart_doc/screens/faculty/faculty_waiting_screen.dart';

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

              if (snapshots.hasError) {
                return Scaffold(
                  body: Center(
                    child: Text('Error checking user role: ${snapshots.error}'),
                  ),
                );
              }
              
              if (!snapshots.hasData || !snapshots.data![0].exists) {
                  // If user doc doesn't exist, they need to select a role.
                  return const RoleSelectionScreen();
              }

              final userSnapshot = snapshots.data![0];
              final facultySnapshot = snapshots.data![1];

              // --- SECURITY GUARDRAIL ---
              // 1. Check for Admin role FIRST. This overrides any other status.
              if (userSnapshot.exists && userSnapshot.data() != null) {
                final userData = userSnapshot.data() as Map<String, dynamic>;
                if (userData['role'] == 'admin') {
                  return const AdminDashboardScreen();
                } 
              }

              // 2. If not an admin, check for Faculty status.
              if (facultySnapshot.exists) {
                final facultyData = facultySnapshot.data() as Map<String, dynamic>;
                if ((facultyData.containsKey('isVerified') && facultyData['isVerified'] == true) ||
                    (facultyData.containsKey('status') && facultyData['status'] == 'approved')) {
                  return const FacultyDashboardScreen();
                } else {
                  return const FacultyWaitingScreen();
                }
              } 
              
              // 3. If not admin or faculty, they must be a student.
              if (userSnapshot.exists) {
                 final userData = userSnapshot.data() as Map<String, dynamic>;
                 if (userData['role'] == 'student') {
                    return const StudentDashboardScreen();
                 }
              }

              // 4. Fallback: If user has no valid role, send to selection.
              return const RoleSelectionScreen();
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
