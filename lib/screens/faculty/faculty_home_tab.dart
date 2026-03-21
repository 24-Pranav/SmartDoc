import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_doc/models/user.dart' as model;
import 'student_documents_screen.dart'; 

class FacultyHomeTab extends StatefulWidget {
  const FacultyHomeTab({super.key});

  @override
  State<FacultyHomeTab> createState() => _FacultyHomeTabState();
}

class _FacultyHomeTabState extends State<FacultyHomeTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
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
        title: const Text('Student Directory'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Students',
                hintText: 'Enter student name or email...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'student')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No students found.'));
                }

                final students = snapshot.data!.docs.map((doc) {
                  return model.User.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
                }).toList();

                final filteredStudents = _searchQuery.isEmpty
                    ? students
                    : students.where((student) {
                        final studentName = student.name ?? '';
                        final studentEmail = student.email ?? '';
                        return studentName.toLowerCase().contains(_searchQuery) ||
                               studentEmail.toLowerCase().contains(_searchQuery);
                      }).toList();

                if (filteredStudents.isEmpty) {
                  return const Center(
                    child: Text('No students match your search.'),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(12.0),
                  itemCount: filteredStudents.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, 
                    crossAxisSpacing: 12.0,
                    mainAxisSpacing: 12.0,
                    childAspectRatio: 0.8, 
                  ),
                  itemBuilder: (context, index) {
                    final student = filteredStudents[index];
                    return Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => StudentDocumentsScreen(student: student),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CircleAvatar(
                                radius: 30,
                                child: Icon(Icons.person, size: 30),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                student.name ?? 'N/A',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                student.email ?? 'N/A',
                                style: Theme.of(context).textTheme.bodySmall,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
