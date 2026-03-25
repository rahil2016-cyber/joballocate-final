import 'package:joballocate/models/resume.dart';
import 'package:joballocate/models/resume_template.dart';
import 'api_service.dart';

class ResumeService {
  final ApiService _apiService = ApiService();

  /// Get all available resume templates (API if present, else bundled defaults).
  Future<List<ResumeTemplate>> getTemplates() async {
    try {
      final templates = await _apiService.getResumeTemplates();
      if (templates.isEmpty) {
        return List<ResumeTemplate>.from(resumeTemplates);
      }
      return templates.map((t) => ResumeTemplate.fromJson(t)).toList();
    } catch (e) {
      return List<ResumeTemplate>.from(resumeTemplates);
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
  }) async {
    try {
      final result = await _apiService.createResume(
        userId,
        token,
        templateId,
        title,
        content,
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
