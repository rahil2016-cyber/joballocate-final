import 'package:flutter/material.dart';

class AppColors {
  // Primary Palette
  // Brand blue taken from the logo text ("JOB").
  static const Color primary = Color(0xFF174A7E);
  static const Color primaryDark = Color(0xFF12365C);
  static const Color primaryLight = Colors.white;

  // Secondary/Accent Palette
  // Updated to match the brand blue from the logo.
  static const Color accent = Color(0xFF174A7E); 
  static const Color accentLight = Color(0xFFEDF2F7); // Very light greyish blue

  // Background Palette
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Colors.white;
  static const Color error = Color(0xFFEF4444);

  // Text Palette
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900
  static const Color textSecondary = Color(0xFF475569); // Slate 600
  static const Color textHint = Color(0xFF94A3B8); // Slate 400

  // Success/Warning Palette
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );
}
