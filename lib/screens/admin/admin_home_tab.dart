import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_doc/models/document.dart';
import 'package:smart_doc/screens/admin/admin_user_detail_screen.dart';
import 'package:smart_doc/models/user.dart' as model;
import 'package:smart_doc/widgets/custom_app_bar.dart';

class AdminHomeTab extends StatelessWidget {
  const AdminHomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Admin Dashboard'),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _getDashboardData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No data available'));
          }

          final data = snapshot.data!;
          final int studentCount = data['studentCount'];
          final int facultyCount = data['facultyCount'];
          final int pendingVerifications = data['pendingVerifications'];
          final Map<DocumentStatus, int> statusCounts = data['statusCounts'];
          final Map<String, int> uploadsByDay = data['uploadsByDay'];
          final Map<String, int> categoryCounts = data['categoryCounts'];
          final List<Document> overdueDocuments = data['overdueDocuments'];

          return _buildDashboard(
            context,
            studentCount,
            facultyCount,
            pendingVerifications,
            statusCounts,
            uploadsByDay,
            categoryCounts,
            overdueDocuments, 
          );
        },
      ),
    );
  }

  Future<Map<String, dynamic>> _getDashboardData() async {
    final usersQuery = FirebaseFirestore.instance.collection('users').get();
    final facultyQuery = FirebaseFirestore.instance.collection('faculty').get();
    final documentsQuery = FirebaseFirestore.instance.collection('documents').get();
    final overdueDocumentsQuery = FirebaseFirestore.instance
        .collection('documents')
        .where('status', isEqualTo: 'pending')
        .where('uploaded_at', isLessThan: DateTime.now().subtract(const Duration(hours: 48)))
        .get();

    final results = await Future.wait([usersQuery, facultyQuery, documentsQuery, overdueDocumentsQuery]);

    final userDocs = (results[0] as QuerySnapshot).docs;
    final facultyDocs = (results[1] as QuerySnapshot).docs;

    final studentCount = userDocs.where((doc) {
      final data = doc.data() as Map<String, dynamic>?;
      return data != null && data['role'] == 'student';
    }).length;

    final facultyCount = facultyDocs.where((doc) {
      final data = doc.data() as Map<String, dynamic>?;
      return data != null && data['status'] == 'approved';
    }).length;

    final pendingVerifications = facultyDocs.where((doc) {
      final data = doc.data() as Map<String, dynamic>?;
      return data != null && data['status'] == 'pending';
    }).length;

    final documents = (results[2] as QuerySnapshot)
        .docs
        .map((doc) => Document.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
        .toList();

    final statusCounts = _getDocumentStatusCounts(documents);
    final uploadsByDay = _getUploadsByDay(documents);
    final categoryCounts = _getCategoryCounts(documents);

    final overdueDocuments = (results[3] as QuerySnapshot)
        .docs
        .map((doc) => Document.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
        .toList();

    return {
      'studentCount': studentCount,
      'facultyCount': facultyCount,
      'pendingVerifications': pendingVerifications,
      'statusCounts': statusCounts,
      'uploadsByDay': uploadsByDay,
      'categoryCounts': categoryCounts,
      'overdueDocuments': overdueDocuments,
    };
  }

  Map<DocumentStatus, int> _getDocumentStatusCounts(List<Document> documents) {
    final Map<DocumentStatus, int> counts = {
      DocumentStatus.approved: 0,
      DocumentStatus.pending: 0,
      DocumentStatus.rejected: 0,
    };
    for (var doc in documents) {
      counts[doc.status] = (counts[doc.status] ?? 0) + 1;
    }
    return counts;
  }

  Map<String, int> _getUploadsByDay(List<Document> documents) {
    final Map<String, int> uploads = {};
    final today = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      final dayKey = DateFormat('EEE').format(date);
      uploads[dayKey] = 0;
    }

    for (var doc in documents) {
      if (doc.uploadedDate.isAfter(today.subtract(const Duration(days: 7)))) {
        final dayKey = DateFormat('EEE').format(doc.uploadedDate);
        if (uploads.containsKey(dayKey)) {
          uploads[dayKey] = uploads[dayKey]! + 1;
        }
      }
    }
    return uploads;
  }

  Map<String, int> _getCategoryCounts(List<Document> documents) {
    final Map<String, int> counts = {};
    for (var doc in documents) {
      counts[doc.category] = (counts[doc.category] ?? 0) + 1;
    }
    return counts;
  }

  Widget _buildDashboard(
    BuildContext context,
    int studentCount,
    int facultyCount,
    int pendingVerifications,
    Map<DocumentStatus, int> statusCounts,
    Map<String, int> uploadsByDay,
    Map<String, int> categoryCounts,
    List<Document> overdueDocuments,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildMetricCards(studentCount, facultyCount, pendingVerifications),
        const SizedBox(height: 24),
        if (overdueDocuments.isNotEmpty)
          _buildOverdueDocumentsCard(context, overdueDocuments),
        const SizedBox(height: 24),
        _buildStatusPieChartCard(context, statusCounts),
        const SizedBox(height: 24),
        _buildUploadsBarChartCard(context, uploadsByDay),
        const SizedBox(height: 24),
        _buildCategoryPieChartCard(context, categoryCounts),
      ],
    );
  }

  Widget _buildMetricCards(
      int studentCount, int facultyCount, int pendingVerifications) {
    return Column(
      children: [
        _buildMetricCard(
            'Total Students', studentCount.toString(), Icons.school, Colors.blue),
        const SizedBox(height: 16),
        _buildMetricCard(
            'Total Faculty', facultyCount.toString(), Icons.person, Colors.green),
        const SizedBox(height: 16),
        _buildMetricCard('Pending Verifications',
            pendingVerifications.toString(), Icons.hourglass_top, Colors.orange),
      ],
    );
  }

  Widget _buildOverdueDocumentsCard(BuildContext context, List<Document> documents) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Global Pending Review (> 48 Hours)',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade800,
                  ),
            ),
            const SizedBox(height: 16),
            ...documents.map((doc) => ListTile(
                  leading: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                  title: Text(doc.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Student: ${doc.studentName} | Uploaded: ${DateFormat.yMd().add_jm().format(doc.uploadedDate)}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final userDoc = await FirebaseFirestore.instance.collection('users').doc(doc.studentId).get();
                    if (userDoc.exists) {
                      final student = model.User.fromFirestore(userDoc.data()!, userDoc.id);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AdminUserDetailScreen(user: student),
                        ),
                      );
                    }
                  },
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(icon, size: 40, color: color),
        title: Text(title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        trailing: Text(value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildStatusPieChartCard(
      BuildContext context, Map<DocumentStatus, int> statusCounts) {
    final List<PieChartSectionData> sections = statusCounts.entries.map((entry) {
      return PieChartSectionData(
        color: _getColorForStatus(entry.key),
        value: entry.value.toDouble(),
        title: '${entry.value}',
        radius: 50.0,
        titleStyle: const TextStyle(
          fontSize: 16.0,
          fontWeight: FontWeight.bold,
          color: Color(0xffffffff),
        ),
      );
    }).toList();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Document Status',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildLegend(statusCounts),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(Map<DocumentStatus, int> statusCounts) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: statusCounts.keys.map((status) {
        return Chip(
          avatar: CircleAvatar(backgroundColor: _getColorForStatus(status)),
          label: Text('${status.name[0].toUpperCase()}${status.name.substring(1)}'),
        );
      }).toList(),
    );
  }

  Color _getColorForStatus(DocumentStatus status) {
    switch (status) {
      case DocumentStatus.approved:
        return Colors.green.shade600;
      case DocumentStatus.pending:
        return Colors.orange.shade600;
      case DocumentStatus.rejected:
        return Colors.red.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  Widget _buildUploadsBarChartCard(BuildContext context, Map<String, int> uploadsByDay) {
    final barGroups = uploadsByDay.entries.map((entry) {
      final dayIndex = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].indexOf(entry.key);
      return BarChartGroupData(
        x: dayIndex,
        barRods: [
          BarChartRodData(
            toY: entry.value.toDouble(),
            color: Colors.blue,
            width: 16,
          )
        ],
      );
    }).toList();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recent Uploads (Last 7 Days)',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: (uploadsByDay.values.isEmpty ? 0 : uploadsByDay.values.reduce((a, b) => a > b ? a : b)) * 1.2,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, meta) {
                        final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                        if (value.toInt() >= 0 && value.toInt() < days.length) {
                          return Text(days[value.toInt()]);
                        }
                        return const Text('');
                      }))),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: barGroups,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryPieChartCard(BuildContext context, Map<String, int> categoryCounts) {
    final List<PieChartSectionData> sections = categoryCounts.entries.map((entry) {
      return PieChartSectionData(
        color: _getColorForCategory(entry.key),
        value: entry.value.toDouble(),
        title: '${entry.value}',
        radius: 60.0,
        titleStyle: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Documents by Category', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildCategoryLegend(categoryCounts),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryLegend(Map<String, int> categoryCounts) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: categoryCounts.keys.map((category) {
        return Chip(
          avatar: CircleAvatar(backgroundColor: _getColorForCategory(category)),
          label: Text(category),
        );
      }).toList(),
    );
  }

  Color _getColorForCategory(String category) {
    final hash = category.hashCode;
    return Color((hash & 0x00FFFFFF) | 0xFF000000);
  }
}
