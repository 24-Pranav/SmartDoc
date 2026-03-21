import 'package:flutter/material.dart';
import 'package:smart_doc/models/document.dart';

class StatusBadge extends StatelessWidget {
  final DocumentStatus status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    String text;
    IconData icon;

    switch (status) {
      case DocumentStatus.approved:
        backgroundColor = Colors.green.shade700;
        text = 'Approved';
        icon = Icons.check_circle;
        break;
      case DocumentStatus.pending:
        backgroundColor = Colors.orange.shade800;
        text = 'Pending';
        icon = Icons.hourglass_bottom;
        break;
      case DocumentStatus.rejected:
        backgroundColor = Colors.red.shade700;
        text = 'Rejected';
        icon = Icons.cancel;
        break;
      case DocumentStatus.resubmission:
        backgroundColor = Colors.blue.shade700;
        text = 'Resubmission';
        icon = Icons.upload_file;
        break;
    }

    return Chip(
      avatar: Icon(icon, color: Colors.white, size: 16),
      label: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      backgroundColor: backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }
}
