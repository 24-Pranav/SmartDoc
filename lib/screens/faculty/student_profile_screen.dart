import 'package:flutter/material.dart';
import 'package:smart_doc/models/student.dart';

class StudentProfileScreen extends StatelessWidget {
  final Student student;

  const StudentProfileScreen({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(student.name),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email: ${student.email}'),
            Text('Student ID: ${student.studentId}'),
            Text('Year: ${student.year}'),
            Text('Section: ${student.section}'),
            // Add more student details here
          ],
        ),
      ),
    );
  }
}
