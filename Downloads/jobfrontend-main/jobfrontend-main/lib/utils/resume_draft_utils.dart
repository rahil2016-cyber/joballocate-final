// Helpers for GET /job-seeker/resume/drafts payloads.

/// Picks the draft flagged `is_primary` or matching `primary_resume_draft_id`.
Map<String, dynamic>? pickPrimaryResumeDraft(Map<String, dynamic> raw) {
  final list = raw['drafts'];
  if (list is! List) return null;

  final pid = raw['primary_resume_draft_id'];
  int? primaryId;
  if (pid is int) {
    primaryId = pid;
  } else if (pid != null) {
    primaryId = int.tryParse(pid.toString());
  }

  Map<String, dynamic>? byFlag;
  Map<String, dynamic>? byId;
  for (final e in list) {
    if (e is! Map) continue;
    final m = Map<String, dynamic>.from(e);
    final idRaw = m['id'];
    final id = idRaw is int
        ? idRaw
        : int.tryParse(idRaw?.toString() ?? '') ?? 0;
    if (m['is_primary'] == true) byFlag = m;
    if (primaryId != null && id == primaryId) byId = m;
  }
  return byFlag ?? byId;
}

/// Best draft to pre-fill a **new** template: primary if set, else most recently updated.
Map<String, dynamic>? pickBestResumeDraftForPrefill(Map<String, dynamic> raw) {
  final primary = pickPrimaryResumeDraft(raw);
  if (primary != null) return primary;

  final list = raw['drafts'];
  if (list is! List || list.isEmpty) return null;

  Map<String, dynamic>? best;
  DateTime bestTime = DateTime.fromMillisecondsSinceEpoch(0);

  for (final e in list) {
    if (e is! Map) continue;
    final m = Map<String, dynamic>.from(e);
    final u = m['updated_at']?.toString() ?? m['created_at']?.toString() ?? '';
    final t = DateTime.tryParse(u) ?? DateTime.fromMillisecondsSinceEpoch(0);
    if (best == null || t.isAfter(bestTime)) {
      best = m;
      bestTime = t;
    }
  }
  return best;
}

/// Parses `content` from a draft map into a JSON map, or null.
Map<String, dynamic>? resumeDraftContentMap(Map<String, dynamic> draft) {
  final c = draft['content'];
  if (c is Map<String, dynamic>) return c;
  if (c is Map) return Map<String, dynamic>.from(c);
  return null;
}
