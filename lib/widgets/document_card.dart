import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_doc/models/document.dart';
import 'package:url_launcher/url_launcher.dart';

class DocumentCard extends StatelessWidget {
  final Document document;

  const DocumentCard({super.key, required this.document});

  // Function to launch the URL
  Future<void> _launchURL(BuildContext context, String? urlString) async {
    if (urlString == null || urlString.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document URL is not available.')),
      );
      return;
    }

    final Uri url = Uri.parse(urlString);

    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch document: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat.yMMMd().format(document.uploadedDate);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        onTap: () => _launchURL(context, document.url), // Added onTap handler
        leading: const Icon(Icons.insert_drive_file, color: Colors.blueGrey, size: 40),
        title: Text(
          document.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Student: ${document.studentName}', maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 5),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getStatusColor().withOpacity(0.2),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    document.status.name.toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(),
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  formattedDate,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  Color _getStatusColor() {
    switch (document.status) {
      case DocumentStatus.pending:
        return Colors.orange.shade800;
      case DocumentStatus.approved:
        return Colors.green.shade800;
      case DocumentStatus.rejected:
        return Colors.red.shade800;
      case DocumentStatus.resubmission:
        return Colors.blue.shade800;
    }
  }
}
