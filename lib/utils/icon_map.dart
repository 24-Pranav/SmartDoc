import 'package:flutter/material.dart';

// A simple utility to map document categories to Material Icons
IconData getIconForCategory(String category) {
  switch (category.toLowerCase()) {
    case 'id card':
      return Icons.badge;
    case 'marksheet':
      return Icons.assignment;
    case 'bonafide':
      return Icons.verified_user;
    case 'fee receipt':
      return Icons.receipt_long;
    case 'certificate':
      return Icons.military_tech;
    default:
      return Icons.article; // Default icon for unknown categories
  }
}