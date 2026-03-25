import 'package:flutter/material.dart';

class AppColors {
  // Primary Palette
  static const Color primary = Color(0xFF2563EB); // Modern Blue
  static const Color primaryDark = Color(0xFF1E40AF);
  static const Color primaryLight = Color(0xFFDBEAFE);

  // Secondary/Accent Palette
  static const Color accent = Color(0xFF7C3AED); // Modern Purple
  static const Color accentLight = Color(0xFFEDE9FE);

  // Background Palette
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Colors.white;
  static const Color error = Color(0xFFEF4444);

  // Text Palette
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textHint = Color(0xFF94A3B8);

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
    colors: [accent, Color(0xFF6D28D9)],
  );
}
