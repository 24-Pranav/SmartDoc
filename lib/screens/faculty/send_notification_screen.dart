import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smart_doc/models/user.dart' as AppUser;

class SendNotificationScreen extends StatefulWidget {
  const SendNotificationScreen({super.key});

  @override
  State<SendNotificationScreen> createState() => _SendNotificationScreenState();
}

class _SendNotificationScreenState extends State<SendNotificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  String _sendTo = 'All Students';
  String? _selectedStudentId;
  List<AppUser.User> _students = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  Future<void> _fetchStudents() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'student')
          .get();
      final students = snapshot.docs
          .map((doc) => AppUser.User.fromFirestore(doc.data(), doc.id))
          .toList();
      setState(() {
        _students = students;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching students: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendNotification() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final faculty = FirebaseAuth.instance.currentUser;
      if (faculty == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be logged in to send notifications.')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Fetch faculty's name
      final facultyDoc = await FirebaseFirestore.instance.collection('users').doc(faculty.uid).get();
      final facultyName = facultyDoc.data()?['name'] ?? 'N/A';

      String targetType = _sendTo == 'All Students' ? 'all' : _selectedStudentId!;

      try {
        await FirebaseFirestore.instance.collection('notifications').add({
          'title': _titleController.text,
          'message': _messageController.text,
          'senderId': faculty.uid,
          'senderName': facultyName, // Include sender's name
          'target': targetType,
          'timestamp': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification sent successfully!')),
        );
        Navigator.of(context).pop();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send notification: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Notification'),
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField(
                controller: _titleController,
                labelText: 'Title',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _messageController,
                labelText: 'Message',
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a message';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              _buildDropdown(
                value: _sendTo,
                items: ['All Students', 'Specific Student']
                    .map((label) => DropdownMenuItem(
                          value: label,
                          child: Text(label),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _sendTo = value!;
                    _selectedStudentId = null;
                  });
                },
                labelText: 'Send To',
              ),
              if (_sendTo == 'Specific Student') ...[
                const SizedBox(height: 16),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildDropdown(
                        value: _selectedStudentId,
                        hint: 'Select Student',
                        items: _students
                            .map((student) => DropdownMenuItem(
                                  value: student.id,
                                  child: Text(student.name ?? 'Unnamed Student'),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedStudentId = value;
                          });
                        },
                        validator: (value) {
                          if (_sendTo == 'Specific Student' && value == null) {
                            return 'Please select a student';
                          }
                          return null;
                        },
                        labelText: 'Student',
                      ),
              ],
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _sendNotification,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Send Notification', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: labelText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: validator,
    );
  }

  Widget _buildDropdown<T>({
    T? value,
    String? hint,
    required List<DropdownMenuItem<T>> items,
    void Function(T?)? onChanged,
    String? Function(T?)? validator,
    required String labelText,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      hint: hint != null ? Text(hint) : null,
      items: items,
      onChanged: onChanged,
      validator: validator,
      decoration: InputDecoration(
        labelText: labelText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
