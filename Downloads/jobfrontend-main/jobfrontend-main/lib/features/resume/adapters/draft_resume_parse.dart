import 'dart:convert';

import 'package:joballocate/features/resume/adapters/resume_model_legacy_adapter.dart';
import 'package:joballocate/features/resume/models/resume_model.dart';
import 'package:joballocate/models/json_resume.dart';

/// Parses persisted draft `content` for previews (legacy JSON Resume or `resume_model_v1`).
JsonResume? jsonResumePreviewFromDraftContent(dynamic raw) {
  try {
    Map<String, dynamic>? map;
    if (raw is Map) {
      map = Map<String, dynamic>.from(raw);
    } else if (raw is String && raw.isNotEmpty) {
      final d = jsonDecode(raw);
      if (d is Map) map = Map<String, dynamic>.from(d);
    }
    if (map == null) return null;
    if (map['schema']?.toString() == kResumeModelSchema) {
      return resumeModelToLegacyJsonResume(resumeModelFromApiEnvelope(map));
    }
    return JsonResume.fromJson(map);
  } catch (_) {
    return null;
  }
}

({ResumeModel? model, JsonResume? legacy}) resumeDraftParseForBuilder(dynamic raw) {
  try {
    Map<String, dynamic>? map;
    if (raw is Map) {
      map = Map<String, dynamic>.from(raw);
    } else if (raw is String && raw.isNotEmpty) {
      final d = jsonDecode(raw);
      if (d is Map) map = Map<String, dynamic>.from(d);
    }
    if (map == null) return (model: null, legacy: null);
    if (map['schema']?.toString() == kResumeModelSchema) {
      return (model: resumeModelFromApiEnvelope(map), legacy: null);
    }
    return (model: null, legacy: JsonResume.fromJson(map));
  } catch (_) {
    return (model: null, legacy: null);
  }
}
