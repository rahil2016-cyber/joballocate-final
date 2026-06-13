import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/resume_model.dart';
import '../services/resume_autosave_service.dart';

/// Override in [ProviderScope] when opening the builder screen.
final resumeInitialProvider = Provider<ResumeModel>((ref) => ResumeModel.empty());

final resumeAutosaveServiceProvider = Provider<ResumeAutosaveService>((ref) {
  final s = ResumeAutosaveService();
  ref.onDispose(s.dispose);
  return s;
});

/// Session context for debounced cloud/local persistence.
final resumeAutosaveContextProvider = Provider<ResumeAutosaveContext>((ref) {
  throw StateError('resumeAutosaveContextProvider must be overridden');
});

class ResumeAutosaveContext {
  const ResumeAutosaveContext({
    required this.userKey,
    required this.token,
    this.existingDraftId,
  });

  final String userKey;
  final String token;
  final String? existingDraftId;
}

final resumeDraftProvider =
    NotifierProvider.autoDispose<ResumeDraftNotifier, ResumeModel>(ResumeDraftNotifier.new);

class ResumeDraftNotifier extends AutoDisposeNotifier<ResumeModel> {
  Timer? _debounce;

  @override
  ResumeModel build() {
    ref.onDispose(() => _debounce?.cancel());
    return ref.read(resumeInitialProvider);
  }

  void _scheduleAutosave() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 850), () {
      try {
        final ctx = ref.read(resumeAutosaveContextProvider);
        ref.read(resumeAutosaveServiceProvider).scheduleSave(
              userKey: ctx.userKey,
              draftId: ctx.existingDraftId,
              model: state,
            );
      } catch (_) {}
    });
  }

  void _bump(ResumeModel next) {
    state = next;
    _scheduleAutosave();
  }

  void replaceAll(ResumeModel m) => _bump(m);

  void setDraftTitle(String v) => _bump(state.copyWith(draftTitle: v));

  void setFullName(String v) => _bump(state.copyWith(fullName: v));

  void setSummary(String v) => _bump(state.copyWith(summary: v));

  void setContact({String? mobile, String? email}) =>
      _bump(state.copyWith(contact: state.contact.copyWith(mobile: mobile, email: email)));

  void setProfileBase64(String? raw, {bool clearUrl = false}) => _bump(
        state.copyWith(
          profileImageBase64: raw,
          clearProfileImageBase64: raw == null,
          clearProfileImageUrl: clearUrl,
        ),
      );

  void setProfileUrl(String? url) =>
      _bump(state.copyWith(profileImageUrl: url, clearProfileImageUrl: url == null));

  void setSkills(List<String> s) => _bump(state.copyWith(skills: List<String>.from(s)));

  void setLanguages(List<String> s) => _bump(state.copyWith(languages: List<String>.from(s)));

  void setCertifications(List<String> s) =>
      _bump(state.copyWith(certifications: List<String>.from(s)));

  void setPersonalDetails(List<PersonalDetailRow> rows) =>
      _bump(state.copyWith(personalDetails: List<PersonalDetailRow>.from(rows)));

  void setEducation(EducationData e) => _bump(state.copyWith(education: e));

  void setInternships(List<ExperienceItem> items) =>
      _bump(state.copyWith(internships: List<ExperienceItem>.from(items)));

  void setProjects(List<ExperienceItem> items) =>
      _bump(state.copyWith(projects: List<ExperienceItem>.from(items)));

  void setWork(List<ExperienceItem> items) =>
      _bump(state.copyWith(workExperience: List<ExperienceItem>.from(items)));

  void setExtraSections(List<DynamicResumeSection> sections) =>
      _bump(state.copyWith(extraSections: List<DynamicResumeSection>.from(sections)));

  void setSectionVisible(String key, bool visible) {
    final m = Map<String, bool>.from(state.sectionVisible);
    m[key] = visible;
    _bump(state.copyWith(sectionVisible: m));
  }

  /// Called after successful Laravel save — keeps Firebase/local aligned with server id.
  void notifyPersistedSnapshot() {
    try {
      final ctx = ref.read(resumeAutosaveContextProvider);
      unawaited(
        ref.read(resumeAutosaveServiceProvider).persistNow(
              userKey: ctx.userKey,
              draftId: ctx.existingDraftId,
              model: state,
            ),
      );
    } catch (_) {}
  }
}

/// Decode image picker bytes to raw base64 for the model (no data-uri prefix).
String bytesToRawBase64(Uint8List bytes) => base64Encode(bytes);
