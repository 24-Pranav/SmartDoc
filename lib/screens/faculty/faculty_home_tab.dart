import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:smart_doc/models/student.dart';
import 'package:smart_doc/screens/faculty/student_profile_screen.dart';

class FacultyHomeTab extends StatefulWidget {
  const FacultyHomeTab({super.key});

  @override
  _FacultyHomeTabState createState() => _FacultyHomeTabState();
}

class _FacultyHomeTabState extends State<FacultyHomeTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Students'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search students...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'student').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No students found.'));
          }

          final allStudents = snapshot.data!.docs.map((doc) => Student.fromFirestore(doc)).toList();

          final filteredStudents = allStudents.where((student) {
            final nameLower = student.name.toLowerCase();
            final searchLower = _searchQuery.toLowerCase();
            return nameLower.contains(searchLower);
          }).toList();

          if (filteredStudents.isEmpty) {
            return const Center(
              child: Text('No students match your search.'),
            );
          }

          return ListView.builder(
            itemCount: filteredStudents.length,
            itemBuilder: (context, index) {
              final student = filteredStudents[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: student.photoURL != null ? NetworkImage(student.photoURL!) : null,
                  child: student.photoURL == null ? const Icon(Icons.person) : null,
                ),
                title: Text(student.name),
                subtitle: Text(student.email),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => StudentProfileScreen(student: student),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
