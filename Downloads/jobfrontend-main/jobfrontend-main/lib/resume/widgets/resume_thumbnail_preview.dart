import 'package:flutter/material.dart';
import 'package:joballocate/features/resume/models/resume_model.dart';
import 'package:joballocate/models/json_resume.dart';
import 'package:joballocate/models/resume_template.dart';

import '../models/resume_sheet_constants.dart';
import '../models/resume_studio_appearance.dart';
import '../templates/resume_template_registry.dart';

/// Miniature live preview for grids/lists (FittedBox scales full A4 layout).
class ResumeThumbnailPreview extends StatelessWidget {
  const ResumeThumbnailPreview({
    super.key,
    required this.template,
    this.resumeModel,
    this.legacyResume,
    required this.height,
    this.appearance = const ResumeStudioAppearance(),
  });

  final ResumeTemplate template;
  final ResumeModel? resumeModel;
  final JsonResume? legacyResume;
  final double height;
  final ResumeStudioAppearance appearance;

  @override
  Widget build(BuildContext context) {
    final ResumeModel model = resumeModel ??
        (legacyResume != null ? ResumeModel.fromLegacyJsonResume(legacyResume!) : ResumeModel.empty());
    final builder = ResumeTemplateRegistry.instance.resolve(template.builderKey);
    Widget sheet;
    try {
      sheet = builder.buildFlutterSheet(context, model, appearance, template);
    } catch (_) {
      sheet = ColoredBox(
        color: const Color(0xFFE0E3E8),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'Preview unavailable',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 11),
            ),
          ),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: FittedBox(
          fit: BoxFit.fitHeight,
          alignment: Alignment.topCenter,
          clipBehavior: Clip.hardEdge,
          child: SizedBox(
            width: kResumeA4Width,
            height: kResumeA4Height,
            child: sheet,
          ),
        ),
      ),
    );
  }
}
