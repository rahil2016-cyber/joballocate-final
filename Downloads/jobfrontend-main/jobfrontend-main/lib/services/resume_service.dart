import 'package:joballocate/models/resume.dart';
import 'package:joballocate/models/resume_template.dart';
import 'api_service.dart';

class ResumeService {
  final ApiService _apiService = ApiService();

  /// Get all available resume templates (API if present, else bundled defaults).
  Future<List<ResumeTemplate>> getTemplates() async {
    final localActive = List<ResumeTemplate>.from(resumeTemplates)
        .where((t) => kActiveResumeTemplateIds.contains(t.id))
        .toList();
    localActive.sort((a, b) => a.id.compareTo(b.id));

    try {
      final raw = await _apiService.getResumeTemplates();
      final apiTemplates = <ResumeTemplate>[];
      for (final row in raw) {
        try {
          apiTemplates.add(ResumeTemplate.fromJson(Map<String, dynamic>.from(row)));
        } catch (_) {}
      }

      // Keep bundled templates first (product-controlled), then append extra
      // API templates that are active but not bundled.
      final localIds = localActive.map((t) => t.id).toSet();
      final apiExtras = apiTemplates
          .where((t) =>
              kActiveResumeTemplateIds.contains(t.id) && !localIds.contains(t.id))
          .toList()
        ..sort((a, b) => a.id.compareTo(b.id));

      return [...localActive, ...apiExtras];
    } catch (e) {
      return localActive;
    }
  }

  /// Get user's resumes
  Future<List<Resume>> getUserResumes(String userId, String token) async {
    try {
      final resumes = await _apiService.getUserResumes(userId, token);
      return resumes
          .map((r) => Resume.fromJson(r))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch resumes: $e');
    }
  }

  /// Create a new resume with specified template
  /// Cost: 20 rupees
  Future<Resume> createResume({
    required String userId,
    required String token,
    required String templateId,
    required String title,
    required Map<String, dynamic> content,
    int? resumeDraftId,
  }) async {
    try {
      final result = await _apiService.createResume(
        userId,
        token,
        templateId,
        title,
        content,
        resumeDraftId,
      );

      final raw = result['resume'] ?? result['data'];
      if (result['success'] == true && raw is Map<String, dynamic>) {
        return Resume.fromJson(raw);
      }
      throw Exception('Failed to create resume');
    } catch (e) {
      throw Exception('Error creating resume: $e');
    }
  }

  /// Update resume content
  Future<void> updateResume({
    required String resumeId,
    required String token,
    required Map<String, dynamic> content,
  }) async {
    try {
      await _apiService.updateResume(resumeId, token, content);
    } catch (e) {
      throw Exception('Error updating resume: $e');
    }
  }

  /// Delete a resume
  Future<void> deleteResume(String resumeId, String token) async {
    try {
      await _apiService.deleteResume(resumeId, token);
    } catch (e) {
      throw Exception('Error deleting resume: $e');
    }
  }

  /// Get a specific template by ID
  Future<ResumeTemplate> getTemplateById(int id) async {
    return resumeTemplates.firstWhere(
      (template) => template.id == id,
      orElse: () => throw Exception('Template not found'),
    );
  }
}
