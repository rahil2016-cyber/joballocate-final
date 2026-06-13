import 'package:flutter/material.dart';

import 'resume_font_family.dart';

/// Editor-controlled styling layered on top of template defaults.
@immutable
class ResumeStudioAppearance {
  const ResumeStudioAppearance({
    this.accentOverride,
    this.headingFont = ResumeFontFamily.openSans,
    this.bodyFont = ResumeFontFamily.openSans,
    this.sheetBrightness = Brightness.light,
  });

  final Color? accentOverride;
  final ResumeFontFamily headingFont;
  final ResumeFontFamily bodyFont;
  final Brightness sheetBrightness;

  Color resolvedAccent(Color templateDefault) => accentOverride ?? templateDefault;

  ResumeStudioAppearance withHeadingFont(ResumeFontFamily h) => ResumeStudioAppearance(
        accentOverride: accentOverride,
        headingFont: h,
        bodyFont: bodyFont,
        sheetBrightness: sheetBrightness,
      );

  ResumeStudioAppearance withBodyFont(ResumeFontFamily b) => ResumeStudioAppearance(
        accentOverride: accentOverride,
        headingFont: headingFont,
        bodyFont: b,
        sheetBrightness: sheetBrightness,
      );

  ResumeStudioAppearance withBrightness(Brightness b) => ResumeStudioAppearance(
        accentOverride: accentOverride,
        headingFont: headingFont,
        bodyFont: bodyFont,
        sheetBrightness: b,
      );

  ResumeStudioAppearance withAccent(Color? accent) => ResumeStudioAppearance(
        accentOverride: accent,
        headingFont: headingFont,
        bodyFont: bodyFont,
        sheetBrightness: sheetBrightness,
      );
}
