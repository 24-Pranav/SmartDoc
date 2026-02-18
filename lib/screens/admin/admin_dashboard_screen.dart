import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_doc/providers/user_provider.dart';
import 'package:smart_doc/screens/admin/admin_profile_tab.dart';
import 'package:smart_doc/screens/admin/admin_users_tab.dart';
import 'package:smart_doc/screens/admin/admin_verification_tab.dart';
import 'package:smart_doc/widgets/custom_app_bar.dart';
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
    const AdminProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Welcome, ${user?.name ?? 'Admin'}!',
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
            icon: Icon(Icons.people),
            label: 'Users',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.verified),
            label: 'Verification',
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
