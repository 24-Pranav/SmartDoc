import 'package:flutter/material.dart';
import 'package:smart_doc/screens/admin/admin_categories_tab.dart';
import 'package:smart_doc/screens/admin/admin_profile_tab.dart';
import 'package:smart_doc/screens/admin/admin_users_tab.dart';
import 'package:smart_doc/screens/admin/admin_verification_tab.dart';
import 'package:smart_doc/screens/role_selection_screen.dart';
import 'package:smart_doc/widgets/custom_bottom_nav_bar.dart';
import 'admin_home_tab.dart';

class AdminDashboardScreen extends StatefulWidget {
  final int initialIndex;
  const AdminDashboardScreen({super.key, this.initialIndex = 0});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  final List<Widget> _widgetOptions = <Widget>[
    const AdminHomeTab(),
    const AdminUsersTab(),
    const AdminVerificationTab(),
    const AdminCategoriesTab(), // Added Categories Tab
    const AdminProfileTab(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) {
        if (didPop) {
          return;
        }
        if (_selectedIndex != 0) {
          setState(() {
            _selectedIndex = 0;
          });
        } else {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
            (Route<dynamic> route) => false,
          );
        }
      },
      child: Scaffold(
        body: _widgetOptions.elementAt(_selectedIndex),
        bottomNavigationBar: CustomBottomNavBar(
          selectedIndex: _selectedIndex,
          onItemTapped: _onItemTapped,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people),
              label: 'Users',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.verified),
              label: 'Verification',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.category), // Added Categories Icon
              label: 'Categories', // Added Categories Label
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
