import 'package:flutter/material.dart';

class AppColors {
  // Change this hex code to your preferred Yellow to update the UI globally
  static const Color primaryBlue = Color(0xFF0B6EBF);
  static const Color sidebarBg = Color(0xFFE8EAF6);
  static const Color backgroundWhite = Colors.white;
  static const Color textBlack = Colors.black87;
  static const Color borderBlue = Color(0xFF0CEFEF);

  // Reference for the Login Card Header (matches your primary theme)
  static const Color loginHeader = Color(0xFF390777);
}

class AppStyles {
  static const TextStyle headerText = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Colors.black,
  );

  static const TextStyle sidebarHeader = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );
}