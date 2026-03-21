import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_doc/providers/user_provider.dart';
import 'package:smart_doc/widgets/custom_bottom_nav_bar.dart';
import 'student_home_tab.dart';
import 'student_notifications_tab.dart';
import 'student_profile_tab.dart';
import 'student_upload_tab.dart';
import 'student_chat_tab.dart'; // Import the new chat tab

class StudentDashboardScreen extends StatefulWidget {
  final int initialIndex;
  const StudentDashboardScreen({super.key, this.initialIndex = 0});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  // Add the StudentChatTab to the list of widgets
  final List<Widget> _widgetOptions = <Widget>[
    const StudentHomeTab(),
    const StudentUploadTab(),
    StudentChatTab(), // Add the chat tab here
    const StudentNotificationsTab(),
    const StudentProfileTab(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _selectedIndex == 0,
      onPopInvoked: (bool didPop) {
        if (didPop) {
          return;
        }
        if (_selectedIndex != 0) {
          setState(() {
            _selectedIndex = 0;
          });
        }
      },
      child: Scaffold(
        body: _widgetOptions.elementAt(_selectedIndex),
        bottomNavigationBar: CustomBottomNavBar(
          selectedIndex: _selectedIndex,
          onItemTapped: _onItemTapped,
          // Add the chat icon to the bottom navigation bar
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.cloud_upload),
              label: 'Upload',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat),
              label: 'Chat',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications),
              label: 'Notifications',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
