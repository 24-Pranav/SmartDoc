
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:smart_doc/models/document.dart';

class AdminAnalyticsTab extends StatelessWidget {
  const AdminAnalyticsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('documents').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.analytics_outlined, size: 100, color: Colors.grey[300]),
                  const SizedBox(height: 20),
                  Text(
                    'No document data available for analytics.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          final documents = snapshot.data!.docs
              .map((doc) => Document.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
              .toList();

          return _buildAnalyticsBody(context, documents);
        },
      ),
    );
  }

  Widget _buildAnalyticsBody(BuildContext context, List<Document> documents) {
    final statusCounts = _getDocumentStatusCounts(documents);
    final categoryCounts = _getDocumentCategoryCounts(documents);

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Text(
          'Analytics & Reports',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[800],
              ),
        ),
        const SizedBox(height: 24),
        _buildStatusPieChartCard(context, statusCounts, documents.length),
        const SizedBox(height: 24),
        _buildCategoryBarChartCard(context, categoryCounts),
      ],
    );
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

  Map<String, int> _getDocumentCategoryCounts(List<Document> documents) {
    final Map<String, int> counts = {};
    for (var doc in documents) {
      counts.update(doc.category, (value) => value + 1, ifAbsent: () => 1);
    }
    return counts;
  }

  Widget _buildStatusPieChartCard(BuildContext context, Map<DocumentStatus, int> statusCounts, int totalDocs) {
    final List<PieChartSectionData> sections = statusCounts.entries.map((entry) {
      const isTouched = false; // Placeholder for future interactivity
      final double fontSize = isTouched ? 18.0 : 14.0;
      final double radius = isTouched ? 60.0 : 50.0;
      return PieChartSectionData(
        color: _getColorForStatus(entry.key),
        value: entry.value.toDouble(),
        title: '${entry.value}',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: const Color(0xffffffff),
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
            Text('Document Status', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
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
          label: Text('${status.name[0].toUpperCase()}${status.name.substring(1)}'), // Capitalize first letter
        );
      }).toList(),
    );
  }

  Widget _buildCategoryBarChartCard(BuildContext context, Map<String, int> categoryCounts) {
    final List<BarChartGroupData> barGroups = [];
    int i = 0;
    categoryCounts.forEach((category, count) {
      barGroups.add(
        BarChartGroupData(
          x: i++,
          barRods: [
            BarChartRodData(
              toY: count.toDouble(),
              color: Colors.amber, // You can have dynamic colors
              width: 16,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    });

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
              height: 250,
              child: categoryCounts.isEmpty
                  ? const Center(child: Text('No documents with categories yet.'))
                  : BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: (categoryCounts.values.isEmpty ? 0 : categoryCounts.values.reduce((a, b) => a > b ? a : b)) * 1.2,
                        barTouchData: BarTouchData(enabled: true),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (double value, TitleMeta meta) {
                                final index = value.toInt();
                                if (index >= 0 && index < categoryCounts.keys.length) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 6.0),
                                    child: Text(categoryCounts.keys.elementAt(index), style: const TextStyle(fontSize: 12)),
                                  );
                                }
                                return const Text('');
                              },
                              reservedSize: 38,
                            ),
                          ),
                          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        gridData: const FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 5),
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
}
