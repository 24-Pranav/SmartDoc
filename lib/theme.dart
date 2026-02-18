import 'package:flutter/material.dart';

// A centralized theme for a professional and clean document management app.
final ThemeData appTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: const Color(0xFF2c3e50), // A deep, professional blue-grey
  scaffoldBackgroundColor: const Color(0xFFf7f9fc), // A very light, clean grey
  
  colorScheme: const ColorScheme.light(
    primary: Color(0xFF2c3e50),      // Main brand color
    secondary: Color(0xFF3498db),     // Accent color for buttons and highlights
    onPrimary: Colors.white,         // Text/icon color on primary background
    onSecondary: Colors.white,        // Text/icon color on secondary background
    background: Color(0xFFf7f9fc),    // App background
    surface: Colors.white,           // Card and dialog backgrounds
    error: Colors.redAccent,         // Error color
    onBackground: Color(0xFF333333),  // Main text color
    onSurface: Color(0xFF333333),     // Text color on cards/surfaces
    onError: Colors.white,           // Text/icon color on error background
  ),

  appBarTheme: const AppBarTheme(
    color: Color(0xFF2c3e50), // Use the primary color for a strong contrast
    elevation: 2, // A bit more shadow for depth
    iconTheme: IconThemeData(color: Colors.white), // White icons for readability
    titleTextStyle: TextStyle(
      color: Colors.white, // White title text
      fontSize: 20,
      fontWeight: FontWeight.w600,
    ),
  ),

  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      foregroundColor: Colors.white, // Text color
      backgroundColor: const Color(0xFF3498db), // Button background using accent color
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    ),
  ),

  inputDecorationTheme: const InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    contentPadding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10.0)),
      borderSide: BorderSide(color: Color(0xFFdfe4ea), width: 1), // Subtle border
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10.0)),
      borderSide: BorderSide(color: Color(0xFFdfe4ea), width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10.0)),
      borderSide: BorderSide(color: Color(0xFF3498db), width: 2), // Highlight focus with accent color
    ),
    labelStyle: TextStyle(color: Colors.black54),
  ),

  cardTheme: CardThemeData(
    elevation: 0.5, // Lighter elevation for a flatter design
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: Color(0xFFdfe4ea), width: 1), // Consistent border with inputs
    ),
    margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8)
  ),

  textTheme: const TextTheme(
    displayLarge: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2c3e50)),
    displayMedium: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF2c3e50)),
    headlineSmall: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF2c3e50)),
    titleLarge: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2c3e50)),
    bodyLarge: TextStyle(fontSize: 16.0, color: Color(0xFF495057)),
    bodyMedium: TextStyle(fontSize: 14.0, color: Color(0xFF495057)),
  ).apply(
    bodyColor: const Color(0xFF495057), // Default text color
    displayColor: const Color(0xFF2c3e50), // Headline color
  ),

  iconTheme: const IconThemeData(
    color: Color(0xFF3498db), // Default icon color using accent
  ),
);
