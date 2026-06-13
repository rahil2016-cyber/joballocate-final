import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:joballocate/features/resume/models/resume_model.dart';
import 'package:joballocate/models/resume_template.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/resume_studio_appearance.dart';

/// Contract for bundled résumé layouts (Flutter preview + ATS PDF widgets).
abstract class ResumeTemplateBuilder {
  const ResumeTemplateBuilder();

  /// Stable key stored on [ResumeTemplate.builderKey].
  String get key;

  String get displayName;

  /// Flutter A4 content (without outer shadow — use [ResumeA4Shell] in impl).
  Widget buildFlutterSheet(
    BuildContext context,
    ResumeModel model,
    ResumeStudioAppearance appearance,
    ResumeTemplate meta,
  );

  /// Single-page PDF body widgets (placed inside [pw.MultiPage] by export service).
  List<pw.Widget> buildPdfWidgets({
    required ResumeModel model,
    required ResumeStudioAppearance appearance,
    required ResumeTemplate meta,
    Uint8List? profileBytes,
  });
}
