import 'package:flutter/material.dart';

import 'package:smart_doc/models/document.dart';

class StatusBadge extends StatelessWidget {
  final DocumentStatus status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    String text;

    switch (status) {
      case DocumentStatus.pending:
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        text = 'Pending';
        break;
      case DocumentStatus.approved:
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        text = 'Approved';
        break;
      case DocumentStatus.rejected:
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        text = 'Rejected';
        break;
      case DocumentStatus.resubmission:
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade800;
        text = 'Resubmission';
        break;
    }

    return Chip(
      label: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
      backgroundColor: backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }
}