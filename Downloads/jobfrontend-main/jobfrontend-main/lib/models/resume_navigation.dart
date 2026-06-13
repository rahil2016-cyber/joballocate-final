import '../features/resume/models/resume_model.dart';
import 'resume_template.dart';

/// Returned when switching templates for an existing resume (future templates).
class ResumeTemplatePickResult {
  final ResumeTemplate template;
  final ResumeModel resume;
  final String? existingResumeId;

  const ResumeTemplatePickResult({
    required this.template,
    required this.resume,
    this.existingResumeId,
  });
}
