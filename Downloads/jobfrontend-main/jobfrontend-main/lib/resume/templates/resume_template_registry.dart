import '../models/resume_builder_ids.dart';
import 'resume_builders_impl.dart';
import 'resume_template_builder.dart';

/// Bundled template builders for previews + PDF export.
class ResumeTemplateRegistry {
  ResumeTemplateRegistry._();

  static final ResumeTemplateRegistry instance = ResumeTemplateRegistry._();

  final Map<String, ResumeTemplateBuilder> _builders = {
    ResumeBuilderIds.minimalAts: const MinimalAtsTemplate(),
    ResumeBuilderIds.modernProfessional: const ModernProfessionalTemplate(),
    ResumeBuilderIds.corporateBlue: const CorporateBlueTemplate(),
    ResumeBuilderIds.creativeClean: const CreativeCleanTemplate(),
    ResumeBuilderIds.executiveResume: const ExecutiveResumeTemplate(),
    ResumeBuilderIds.fresherResume: const FresherResumeTemplate(),
    ResumeBuilderIds.darkProfessional: const DarkProfessionalTemplate(),
    ResumeBuilderIds.twoColumnResume: const TwoColumnResumeTemplate(),
    ResumeBuilderIds.compactAts: const CompactAtsTemplate(),
    ResumeBuilderIds.elegantModern: const ElegantModernTemplate(),
  };

  ResumeTemplateBuilder resolve(String? builderKey) {
    final k = builderKey ?? ResumeBuilderIds.minimalAts;
    return _builders[k] ?? _builders[ResumeBuilderIds.minimalAts]!;
  }
}
