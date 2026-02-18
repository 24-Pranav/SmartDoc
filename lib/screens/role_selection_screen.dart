import 'package:flutter/material.dart';
import 'package:smart_doc/screens/login_screen.dart';
import 'package:smart_doc/models/role.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const Text(
                      'Welcome to SmartDoc!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Please select your role to continue',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 48),
                    _RoleCard(
                      icon: Icons.school,
                      label: 'Student',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginScreen(role: Role.student)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _RoleCard(
                      icon: Icons.group,
                      label: 'Faculty',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginScreen(role: Role.faculty)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _RoleCard(
                      icon: Icons.security,
                      label: 'Admin',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginScreen(role: Role.admin)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            children: [
              Icon(
                icon,
                size: 60,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 16),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
