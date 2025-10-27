import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_doc/models/document.dart' as doc_model;
import 'package:smart_doc/models/user.dart' as user_model;
import 'package:smart_doc/models/faculty.dart' as faculty_model;
import 'package:smart_doc/models/role.dart';
import 'package:fl_chart/fl_chart.dart';

class AdminHomeTab extends StatefulWidget {
  const AdminHomeTab({super.key});

  @override
  State<AdminHomeTab> createState() => _AdminHomeTabState();
}

class _AdminHomeTabState extends State<AdminHomeTab> {
  int _userCount = 0;
  int _facultyCount = 0;
  int _documentCount = 0;
  List<doc_model.Document> _recentDocuments = [];
  Map<String, int> _userRoleDistribution = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
      final facultySnapshot = await FirebaseFirestore.instance.collection('faculty').get();
      final allDocumentsSnapshot = await FirebaseFirestore.instance.collection('documents').get();

      final users = usersSnapshot.docs.map((doc) => user_model.User.fromFirestore(doc.data(), doc.id)).toList();
      final faculty = facultySnapshot.docs.map((doc) => faculty_model.Faculty.fromFirestore(doc)).toList();

      final facultyMap = {for (var f in faculty) f.id: f};

      final roles = <String, int>{
        'student': users.where((u) => u.role == Role.student).length,
        'admin': users.where((u) => u.role == Role.admin).length,
        'faculty': faculty.length,
      };

      final documents = allDocumentsSnapshot.docs.map((doc) => doc_model.Document.fromFirestore(doc.data(), doc.id)).toList();
      final facultyDocuments = documents.where((doc) => facultyMap.containsKey(doc.uploadedByUserId)).toList();

      final recentDocuments = facultyDocuments.take(5).toList();

      if (mounted) {
        setState(() {
          _userCount = users.length;
          _facultyCount = faculty.length;
          _documentCount = facultyDocuments.length;
          _recentDocuments = recentDocuments;
          _userRoleDistribution = roles;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch dashboard data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchDashboardData,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  _buildStatsCards(),
                  const SizedBox(height: 24),
                  _buildUserDistributionChart(),
                  const SizedBox(height: 24),
                  _buildRecentDocuments(),
                ],
              ),
            ),
    );
  }

  Widget _buildStatsCards() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildStatCard('Total Users', '$_userCount', Icons.people, Colors.blue),
        _buildStatCard('Total Documents', '$_documentCount', Icons.insert_drive_file, Colors.green),
        _buildStatCard('Faculty', '$_facultyCount', Icons.school, Colors.orange),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(title, style: TextStyle(fontSize: 16, color: Colors.grey[600])),
            Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildUserDistributionChart() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('User Roles', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: _userRoleDistribution.entries.map((entry) {
                    const isTouched = false;
                    final fontSize = isTouched ? 25.0 : 16.0;
                    final radius = isTouched ? 60.0 : 50.0;
                    return PieChartSectionData(
                      color: _getColorForRole(entry.key),
                      value: entry.value.toDouble(),
                      title: '${entry.value}',
                      radius: radius,
                      titleStyle: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xffffffff),
                      ),
                    );
                  }).toList(),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              children: _userRoleDistribution.keys.map((role) {
                return Chip(
                  avatar: CircleAvatar(backgroundColor: _getColorForRole(role)),
                  label: Text(role.toUpperCase()),
                );
              }).toList(),
            )
          ],
        ),
      ),
    );
  }

  Color _getColorForRole(String role) {
    switch (role) {
      case 'student':
        return Colors.blue;
      case 'faculty':
        return Colors.orange;
      case 'admin':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildRecentDocuments() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Recent Documents', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _recentDocuments.isEmpty
                ? const Text('No recent documents from faculty.')
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _recentDocuments.length,
                    itemBuilder: (context, index) {
                      final doc = _recentDocuments[index];
                      return ListTile(
                        leading: const Icon(Icons.description),
                        title: Text(doc.name),
                        subtitle: Text('Uploaded on: ${doc.uploadedDate.substring(0, 10)}'),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
