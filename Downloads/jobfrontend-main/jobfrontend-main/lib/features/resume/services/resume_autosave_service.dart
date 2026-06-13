import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/resume_model.dart';

typedef ResumeRemoteSaveResult = ({bool ok, String? error});

/// Debounced hybrid persistence: SharedPreferences always; Firestore when Firebase is initialized.
class ResumeAutosaveService {
  ResumeAutosaveService({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  static const _prefsPrefix = 'resume_model_autosave_v1_';

  Timer? _debounce;

  bool get _canUseFirestore => Firebase.apps.isNotEmpty;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  void scheduleSave({
    required String userKey,
    required String? draftId,
    required ResumeModel model,
    Duration delay = const Duration(milliseconds: 900),
  }) {
    _debounce?.cancel();
    _debounce = Timer(delay, () {
      unawaited(persistNow(userKey: userKey, draftId: draftId, model: model));
    });
  }

  Future<ResumeRemoteSaveResult> persistNow({
    required String userKey,
    required String? draftId,
    required ResumeModel model,
  }) async {
    final compositeKey = '${userKey}_${draftId ?? 'new'}';
    final prefs = await SharedPreferences.getInstance();
    final payload = jsonEncode(resumeModelToApiEnvelope(model));
    await prefs.setString('$_prefsPrefix$compositeKey', payload);

    if (!_canUseFirestore) {
      return (ok: true, error: null);
    }

    try {
      final docId = draftId ?? 'local_${userKey.hashCode}';
      await _db
          .collection('job_seeker_resume_drafts')
          .doc(userKey)
          .collection('drafts')
          .doc(docId)
          .set({
        'payload': resumeModelToApiEnvelope(model),
        'updated_at': FieldValue.serverTimestamp(),
        'template_id': model.templateId,
      }, SetOptions(merge: true));
      return (ok: true, error: null);
    } catch (e, st) {
      debugPrint('Firestore resume autosave: $e\n$st');
      return (ok: false, error: '$e');
    }
  }

  Future<ResumeModel?> loadLocalSnapshot({
    required String userKey,
    required String? draftId,
  }) async {
    final compositeKey = '${userKey}_${draftId ?? 'new'}';
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefsPrefix$compositeKey');
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw);
      if (map is Map<String, dynamic>) {
        return resumeModelFromApiEnvelope(map);
      }
    } catch (_) {}
    return null;
  }

  void dispose() => _debounce?.cancel();
}
