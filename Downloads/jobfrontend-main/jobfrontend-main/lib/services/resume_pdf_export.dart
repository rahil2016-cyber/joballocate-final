import 'dart:typed_data';

import '../features/resume/models/resume_model.dart';
import '../features/resume/services/resume_pdf_export_service.dart';
import '../models/json_resume.dart';
import '../models/resume_template.dart';

/// Builds ATS-oriented PDFs via [ResumeModel]; legacy [JsonResume] drafts are converted best-effort.
Future<Uint8List> exportResumePdfForTemplate(JsonResume r, int templateId) async {
  final model = ResumeModel.fromLegacyJsonResume(r);
  final t = resumeTemplateById(templateId) ?? resumeTemplates.first;
  return exportResumePdf(model: model, templateMeta: t);
}
