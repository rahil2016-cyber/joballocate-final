import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/resume_font_family.dart';
import '../models/resume_studio_appearance.dart';

class ResumeStudioAppearanceNotifier extends Notifier<ResumeStudioAppearance> {
  @override
  ResumeStudioAppearance build() => const ResumeStudioAppearance();

  /// Null clears override so the template default accent is used.
  void setAccent(Color? color) => state = state.withAccent(color);

  void setHeadingFont(ResumeFontFamily f) => state = state.withHeadingFont(f);

  void setBodyFont(ResumeFontFamily f) => state = state.withBodyFont(f);

  void setSheetBrightness(Brightness b) => state = state.withBrightness(b);

  void resetToDefaults() => state = const ResumeStudioAppearance();
}

final resumeStudioAppearanceProvider =
    NotifierProvider<ResumeStudioAppearanceNotifier, ResumeStudioAppearance>(
  ResumeStudioAppearanceNotifier.new,
);
