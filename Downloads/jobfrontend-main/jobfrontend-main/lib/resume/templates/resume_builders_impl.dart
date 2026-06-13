import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:joballocate/features/resume/models/resume_model.dart';
import 'package:joballocate/models/resume_template.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/resume_builder_ids.dart';
import '../models/resume_studio_appearance.dart';
import '../pdf/resume_pdf_templates.dart';
import '../widgets/resume_a4_shell.dart';
import '../widgets/resume_layouts.dart';
import '../widgets/resume_typography.dart';
import 'resume_template_builder.dart';

ResumeTypography _typography(ResumeTemplate meta, ResumeStudioAppearance appearance) {
  final accent = appearance.resolvedAccent(Color(safeResumeTemplateAccentArgb(meta)));
  return ResumeTypography.merge(
    accent: accent,
    appearance: appearance,
    forcedBrightness: appearance.sheetBrightness,
  );
}

Color _sheetSurface(ResumeStudioAppearance appearance) =>
    appearance.sheetBrightness == Brightness.dark ? const Color(0xFF121212) : Colors.white;

class MinimalAtsTemplate extends ResumeTemplateBuilder {
  const MinimalAtsTemplate();
  @override
  String get key => ResumeBuilderIds.minimalAts;

  @override
  String get displayName => 'Minimal ATS';

  @override
  Widget buildFlutterSheet(
    BuildContext context,
    ResumeModel model,
    ResumeStudioAppearance appearance,
    ResumeTemplate meta,
  ) {
    final typo = _typography(meta, appearance);
    return ResumeA4Shell(
      backgroundColor: _sheetSurface(appearance),
      child: MinimalAtsLayout(model: model, typography: typo),
    );
  }

  @override
  List<pw.Widget> buildPdfWidgets({
    required ResumeModel model,
    required ResumeStudioAppearance appearance,
    required ResumeTemplate meta,
    Uint8List? profileBytes,
  }) {
    return buildResumePdfForTemplate(
      builderKey: key,
      model: model,
      appearance: appearance,
      meta: meta,
      profileBytes: profileBytes,
    );
  }
}

class ModernProfessionalTemplate extends ResumeTemplateBuilder {
  const ModernProfessionalTemplate();
  @override
  String get key => ResumeBuilderIds.modernProfessional;

  @override
  String get displayName => 'Modern Professional';

  @override
  Widget buildFlutterSheet(
    BuildContext context,
    ResumeModel model,
    ResumeStudioAppearance appearance,
    ResumeTemplate meta,
  ) {
    final typo = _typography(meta, appearance);
    return ResumeA4Shell(
      backgroundColor: _sheetSurface(appearance),
      child: ModernProfessionalLayout(model: model, typography: typo),
    );
  }

  @override
  List<pw.Widget> buildPdfWidgets({
    required ResumeModel model,
    required ResumeStudioAppearance appearance,
    required ResumeTemplate meta,
    Uint8List? profileBytes,
  }) {
    return buildResumePdfForTemplate(
      builderKey: key,
      model: model,
      appearance: appearance,
      meta: meta,
      profileBytes: profileBytes,
    );
  }
}

class CorporateBlueTemplate extends ResumeTemplateBuilder {
  const CorporateBlueTemplate();
  @override
  String get key => ResumeBuilderIds.corporateBlue;

  @override
  String get displayName => 'Corporate Blue';

  @override
  Widget buildFlutterSheet(
    BuildContext context,
    ResumeModel model,
    ResumeStudioAppearance appearance,
    ResumeTemplate meta,
  ) {
    final typo = _typography(meta, appearance);
    return ResumeA4Shell(
      backgroundColor: _sheetSurface(appearance),
      child: CorporateBlueLayout(model: model, typography: typo),
    );
  }

  @override
  List<pw.Widget> buildPdfWidgets({
    required ResumeModel model,
    required ResumeStudioAppearance appearance,
    required ResumeTemplate meta,
    Uint8List? profileBytes,
  }) {
    return buildResumePdfForTemplate(
      builderKey: key,
      model: model,
      appearance: appearance,
      meta: meta,
      profileBytes: profileBytes,
    );
  }
}

class CreativeCleanTemplate extends ResumeTemplateBuilder {
  const CreativeCleanTemplate();
  @override
  String get key => ResumeBuilderIds.creativeClean;

  @override
  String get displayName => 'Creative Clean';

  @override
  Widget buildFlutterSheet(
    BuildContext context,
    ResumeModel model,
    ResumeStudioAppearance appearance,
    ResumeTemplate meta,
  ) {
    final typo = _typography(meta, appearance);
    return ResumeA4Shell(
      backgroundColor: _sheetSurface(appearance),
      child: CreativeCleanLayout(model: model, typography: typo),
    );
  }

  @override
  List<pw.Widget> buildPdfWidgets({
    required ResumeModel model,
    required ResumeStudioAppearance appearance,
    required ResumeTemplate meta,
    Uint8List? profileBytes,
  }) {
    return buildResumePdfForTemplate(
      builderKey: key,
      model: model,
      appearance: appearance,
      meta: meta,
      profileBytes: profileBytes,
    );
  }
}

class ExecutiveResumeTemplate extends ResumeTemplateBuilder {
  const ExecutiveResumeTemplate();
  @override
  String get key => ResumeBuilderIds.executiveResume;

  @override
  String get displayName => 'Executive Resume';

  @override
  Widget buildFlutterSheet(
    BuildContext context,
    ResumeModel model,
    ResumeStudioAppearance appearance,
    ResumeTemplate meta,
  ) {
    final typo = _typography(meta, appearance);
    return ResumeA4Shell(
      backgroundColor: _sheetSurface(appearance),
      child: ExecutiveResumeLayout(model: model, typography: typo),
    );
  }

  @override
  List<pw.Widget> buildPdfWidgets({
    required ResumeModel model,
    required ResumeStudioAppearance appearance,
    required ResumeTemplate meta,
    Uint8List? profileBytes,
  }) {
    return buildResumePdfForTemplate(
      builderKey: key,
      model: model,
      appearance: appearance,
      meta: meta,
      profileBytes: profileBytes,
    );
  }
}

class FresherResumeTemplate extends ResumeTemplateBuilder {
  const FresherResumeTemplate();
  @override
  String get key => ResumeBuilderIds.fresherResume;

  @override
  String get displayName => 'Fresher Resume';

  @override
  Widget buildFlutterSheet(
    BuildContext context,
    ResumeModel model,
    ResumeStudioAppearance appearance,
    ResumeTemplate meta,
  ) {
    final typo = _typography(meta, appearance);
    return ResumeA4Shell(
      backgroundColor: _sheetSurface(appearance),
      child: FresherResumeLayout(model: model, typography: typo),
    );
  }

  @override
  List<pw.Widget> buildPdfWidgets({
    required ResumeModel model,
    required ResumeStudioAppearance appearance,
    required ResumeTemplate meta,
    Uint8List? profileBytes,
  }) {
    return buildResumePdfForTemplate(
      builderKey: key,
      model: model,
      appearance: appearance,
      meta: meta,
      profileBytes: profileBytes,
    );
  }
}

class DarkProfessionalTemplate extends ResumeTemplateBuilder {
  const DarkProfessionalTemplate();
  @override
  String get key => ResumeBuilderIds.darkProfessional;

  @override
  String get displayName => 'Dark Professional';

  @override
  Widget buildFlutterSheet(
    BuildContext context,
    ResumeModel model,
    ResumeStudioAppearance appearance,
    ResumeTemplate meta,
  ) {
    final typo = _typography(meta, appearance);
    return ResumeA4Shell(
      backgroundColor: _sheetSurface(appearance),
      child: DarkProfessionalLayout(model: model, typography: typo),
    );
  }

  @override
  List<pw.Widget> buildPdfWidgets({
    required ResumeModel model,
    required ResumeStudioAppearance appearance,
    required ResumeTemplate meta,
    Uint8List? profileBytes,
  }) {
    return buildResumePdfForTemplate(
      builderKey: key,
      model: model,
      appearance: appearance,
      meta: meta,
      profileBytes: profileBytes,
    );
  }
}

class TwoColumnResumeTemplate extends ResumeTemplateBuilder {
  const TwoColumnResumeTemplate();
  @override
  String get key => ResumeBuilderIds.twoColumnResume;

  @override
  String get displayName => 'Two Column Resume';

  @override
  Widget buildFlutterSheet(
    BuildContext context,
    ResumeModel model,
    ResumeStudioAppearance appearance,
    ResumeTemplate meta,
  ) {
    final typo = _typography(meta, appearance);
    return ResumeA4Shell(
      backgroundColor: _sheetSurface(appearance),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      child: TwoColumnResumeLayout(model: model, typography: typo),
    );
  }

  @override
  List<pw.Widget> buildPdfWidgets({
    required ResumeModel model,
    required ResumeStudioAppearance appearance,
    required ResumeTemplate meta,
    Uint8List? profileBytes,
  }) {
    return buildResumePdfForTemplate(
      builderKey: key,
      model: model,
      appearance: appearance,
      meta: meta,
      profileBytes: profileBytes,
    );
  }
}

class CompactAtsTemplate extends ResumeTemplateBuilder {
  const CompactAtsTemplate();
  @override
  String get key => ResumeBuilderIds.compactAts;

  @override
  String get displayName => 'Compact ATS';

  @override
  Widget buildFlutterSheet(
    BuildContext context,
    ResumeModel model,
    ResumeStudioAppearance appearance,
    ResumeTemplate meta,
  ) {
    final typo = _typography(meta, appearance);
    return ResumeA4Shell(
      backgroundColor: _sheetSurface(appearance),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      child: CompactAtsLayout(model: model, typography: typo),
    );
  }

  @override
  List<pw.Widget> buildPdfWidgets({
    required ResumeModel model,
    required ResumeStudioAppearance appearance,
    required ResumeTemplate meta,
    Uint8List? profileBytes,
  }) {
    return buildResumePdfForTemplate(
      builderKey: key,
      model: model,
      appearance: appearance,
      meta: meta,
      profileBytes: profileBytes,
    );
  }
}

class ElegantModernTemplate extends ResumeTemplateBuilder {
  const ElegantModernTemplate();
  @override
  String get key => ResumeBuilderIds.elegantModern;

  @override
  String get displayName => 'Elegant Modern';

  @override
  Widget buildFlutterSheet(
    BuildContext context,
    ResumeModel model,
    ResumeStudioAppearance appearance,
    ResumeTemplate meta,
  ) {
    final typo = _typography(meta, appearance);
    return ResumeA4Shell(
      backgroundColor: _sheetSurface(appearance),
      child: ElegantModernLayout(model: model, typography: typo),
    );
  }

  @override
  List<pw.Widget> buildPdfWidgets({
    required ResumeModel model,
    required ResumeStudioAppearance appearance,
    required ResumeTemplate meta,
    Uint8List? profileBytes,
  }) {
    return buildResumePdfForTemplate(
      builderKey: key,
      model: model,
      appearance: appearance,
      meta: meta,
      profileBytes: profileBytes,
    );
  }
}
