import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_doc/providers/user_provider.dart';
import 'package:smart_doc/screens/faculty/send_notification_screen.dart';

import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_nav_bar.dart';
import 'faculty_home_tab.dart';
import 'faculty_verify_tab.dart';
import 'faculty_notifications_tab.dart';
import 'faculty_profile_tab.dart';

class FacultyDashboardScreen extends StatefulWidget {
  const FacultyDashboardScreen({super.key});

  @override
  State<FacultyDashboardScreen> createState() => _FacultyDashboardScreenState();
}

class _FacultyDashboardScreenState extends State<FacultyDashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _widgetOptions = <Widget>[
    const FacultyHomeTab(),
    const FacultyVerifyTab(),
    const FacultyNotificationsTab(),
    const FacultyProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Welcome, ${user?.fullName ?? 'Faculty'}!',
        showLogout: true,
      ),
      body: _widgetOptions.elementAt(_selectedIndex),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const SendNotificationScreen(),
            ),
          );
        },
        child: const Icon(Icons.send),
      ),
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
            icon: Icon(Icons.verified_user),
            label: 'Verify',
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
