import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/resume_font_family.dart';
import '../models/resume_studio_appearance.dart';

/// Derived text styles for a résumé sheet (Flutter preview).
class ResumeTypography {
  ResumeTypography({
    required this.accent,
    required this.primary,
    required this.secondary,
    required this.headingFamily,
    required this.bodyFamily,
    this.scale = 1.0,
  });

  final Color accent;
  final Color primary;
  final Color secondary;
  final ResumeFontFamily headingFamily;
  final ResumeFontFamily bodyFamily;
  final double scale;

  static ResumeTypography merge({
    required Color accent,
    required ResumeStudioAppearance appearance,
    required Brightness forcedBrightness,
    double scale = 1,
  }) {
    final dark = forcedBrightness == Brightness.dark;
    return ResumeTypography(
      accent: accent,
      primary: dark ? Colors.white : Colors.black87,
      secondary: dark ? Colors.white70 : Colors.black54,
      headingFamily: appearance.headingFont,
      bodyFamily: appearance.bodyFont,
      scale: scale,
    );
  }

  TextStyle _heading(double size, FontWeight w, Color color) {
    switch (headingFamily) {
      case ResumeFontFamily.openSans:
        return GoogleFonts.openSans(fontSize: size * scale, fontWeight: w, color: color);
      case ResumeFontFamily.lato:
        return GoogleFonts.lato(fontSize: size * scale, fontWeight: w, color: color);
      case ResumeFontFamily.merriweather:
        return GoogleFonts.merriweather(fontSize: size * scale, fontWeight: w, color: color);
      case ResumeFontFamily.sourceSans3:
        return GoogleFonts.sourceSans3(fontSize: size * scale, fontWeight: w, color: color);
    }
  }

  TextStyle _body(double size, Color color, {double height = 1.35, FontWeight? w}) {
    switch (bodyFamily) {
      case ResumeFontFamily.openSans:
        return GoogleFonts.openSans(fontSize: size * scale, height: height, color: color, fontWeight: w);
      case ResumeFontFamily.lato:
        return GoogleFonts.lato(fontSize: size * scale, height: height, color: color, fontWeight: w);
      case ResumeFontFamily.merriweather:
        return GoogleFonts.merriweather(fontSize: size * scale, height: height, color: color, fontWeight: w);
      case ResumeFontFamily.sourceSans3:
        return GoogleFonts.sourceSans3(fontSize: size * scale, height: height, color: color, fontWeight: w);
    }
  }

  TextStyle nameLarge([FontWeight w = FontWeight.w800]) => _heading(28 * scale, w, primary);

  TextStyle titleLine([FontWeight w = FontWeight.w600]) => _heading(13 * scale, w, accent);

  TextStyle sectionCaps([FontWeight w = FontWeight.w800]) =>
      _heading(11.5 * scale, w, primary).copyWith(letterSpacing: 0.85);

  TextStyle body([double size = 11]) => _body(size, primary);

  TextStyle caption([double size = 10]) => _body(size, secondary);

  TextStyle accentText(double size, FontWeight w) => _body(size, accent, w: w, height: 1.25);

  TextStyle inverseTitle(Color onAccent, double size, FontWeight w) =>
      _heading(size, w, onAccent);
}
