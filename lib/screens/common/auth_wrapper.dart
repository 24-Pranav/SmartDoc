import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_doc/models/role.dart';
import 'package:smart_doc/models/user.dart';
import 'package:smart_doc/screens/admin/admin_dashboard_screen.dart';
import 'package:smart_doc/screens/faculty/faculty_dashboard_screen.dart';
import 'package:smart_doc/screens/faculty/faculty_waiting_screen.dart';
import 'package:smart_doc/screens/role_selection_screen.dart';
import 'package:smart_doc/screens/student/student_dashboard_screen.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/material.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<auth.User?>(
      stream: auth.FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          return FutureBuilder<List<DocumentSnapshot>>(
            future: Future.wait([
              FirebaseFirestore.instance.collection('users').doc(snapshot.data!.uid).get(),
              FirebaseFirestore.instance.collection('faculty').doc(snapshot.data!.uid).get(),
            ]),
            builder: (context, snapshots) {
              if (snapshots.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final userSnapshot = snapshots.data![0];
              final facultySnapshot = snapshots.data![1];

              if (userSnapshot.exists) {
                final userData = User.fromFirestore(userSnapshot.data() as Map<String, dynamic>, userSnapshot.id);
                if (userData.role == Role.admin) {
                  return const AdminDashboardScreen();
                }
              }

              if (facultySnapshot.exists) {
                final status = facultySnapshot['status'];
                if (status == 'approved') {
                  return const FacultyDashboardScreen();
                } else {
                  return const FacultyWaitingScreen();
                }
              }

              if (userSnapshot.exists) {
                final userData = User.fromFirestore(userSnapshot.data() as Map<String, dynamic>, userSnapshot.id);
                if (userData.role == Role.student) {
                  return const StudentDashboardScreen();
                }
              }

              return const RoleSelectionScreen();
            },
          );
        }

        return const RoleSelectionScreen();
      },
    );
  }
}
