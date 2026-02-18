import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_doc/providers/user_provider.dart';
import 'package:smart_doc/widgets/custom_app_bar.dart';
import 'package:smart_doc/widgets/custom_bottom_nav_bar.dart';
import 'student_home_tab.dart';
import 'student_notifications_tab.dart';
import 'student_profile_tab.dart';
import 'student_upload_tab.dart';

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

  final List<Widget> _widgetOptions = <Widget>[
    const StudentHomeTab(),
    const StudentUploadTab(),
    const StudentNotificationsTab(),
    const StudentProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Welcome, ${user?.name ?? 'Student'}!',
        showLogout: true,
      ),
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
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
            icon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
