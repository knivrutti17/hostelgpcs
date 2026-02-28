import 'package:flutter/material.dart';

class AppStyle {
  // --- PRIMARY COLORS ---
  static const Color primaryTeal = Color(0xFF4A9082);
  static const Color secondaryTeal = Color(0xFF67B7A4);
  static const Color accentTeal = Color(0xFFD1EBE5);
  static const Color darkTeal = Color(0xFF2E9B8F);

  // --- NEUTRAL COLORS ---
  static const Color bgWhite = Colors.white;
  static const Color bgLightGrey = Color(0xFFF5F7F8);
  static const Color textGrey = Colors.grey;
  static const Color statusOrange = Colors.orange;

  // --- GRADIENTS ---
  static const LinearGradient headerGradient = LinearGradient(
    colors: [secondaryTeal, primaryTeal],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // --- TEXT STYLES ---
  static const TextStyle headingStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static const TextStyle subtitleStyle = TextStyle(
    fontSize: 16,
    color: Colors.white70,
  );

  // --- DECORATIONS ---
  static BoxDecoration cardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(15),
    border: Border.all(color: Colors.grey.shade200),
    boxShadow: [
      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
    ],
  );
}