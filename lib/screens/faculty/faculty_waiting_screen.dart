import 'package:flutter/material.dart';

class FacultyWaitingScreen extends StatelessWidget {
  const FacultyWaitingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('Your registration is pending approval from the admin.'),
          ],
        ),
      ),
    );
  }
}
