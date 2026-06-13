import 'dart:ui';

import 'package:pdf/pdf.dart';

/// Curated ATS presets: one proven two-column layout; accents only (no graphics-heavy layouts).
const int kResumeAtsVariantMin = 11;
const int kResumeAtsVariantMax = 20;

Color accentColorForDesignVariant(int designVariant) {
  final v = designVariant.clamp(kResumeAtsVariantMin, kResumeAtsVariantMax);
  switch (v) {
    case 11:
      return const Color(0xFF0D7377); // Executive teal
    case 12:
      return const Color(0xFF1B4F72); // Corporate navy
    case 13:
      return const Color(0xFF2C3E50); // Charcoal pro
    case 14:
      return const Color(0xFF1E5631); // Forest
    case 15:
      return const Color(0xFF6B2D3C); // Burgundy classic
    case 16:
      return const Color(0xFF34495E); // Slate modern
    case 17:
      return const Color(0xFF1565C0); // Ocean blue
    case 18:
      return const Color(0xFF5E35B1); // Plum accent
    case 19:
      return const Color(0xFF00695C); // Steel teal
    case 20:
    default:
      return const Color(0xFF37474F); // Graphite
  }
}

PdfColor pdfAccentForDesignVariant(int designVariant) {
  final c = accentColorForDesignVariant(designVariant);
  return PdfColor(c.r, c.g, c.b);
}

bool isResumeOneDesignVariant(int designVariant) =>
    designVariant >= kResumeAtsVariantMin && designVariant <= kResumeAtsVariantMax;
