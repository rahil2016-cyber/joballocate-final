import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../constants/industry_types.dart';
import '../models/job.dart';
import '../models/resume_demo_view_profile.dart';
import '../models/seeker_popular_category.dart';
import '../models/top_company.dart';
import '../utils/api_json_decode.dart';
import 'package:flutter/material.dart';
import '../main.dart' show RoleSelectionScreen;
import '../navigation/app_navigator.dart' show rootNavigatorKey;
import 'app_session.dart';

/// Public job board + authenticated seeker actions (`/api/v1/jobs`, `/job-seeker/...`).
class JobSeekerApiService {
  JobSeekerApiService._();
  static final JobSeekerApiService instance = JobSeekerApiService._();

  String get _base => ApiConfig.baseUrl;

  Map<String, String> get _publicHeaders => {'Accept': 'application/json'};

  Map<String, String> get _authHeaders {
    final t = AppSession.token;
    if (t == null || t.isEmpty) {
      throw StateError('Not authenticated');
    }
    return {
      'Authorization': 'Bearer $t',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  Map<String, dynamic> _decode(http.Response r) => decodeApiJsonObject(r);

  void _ensureSuccess(Map<String, dynamic> json, int status) {
    if (status >= 200 && status < 300 && json['success'] == true) return;
    final msg = json['message']?.toString() ?? '';
    final lower = msg.toLowerCase();
    if (status == 401 ||
        lower.contains('unauthenticated') ||
        lower.contains('not authenticated')) {
      // Clear invalid session and redirect to login screen
      AppSession.clear();
      rootNavigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
        (_) => false,
      );
      throw Exception('Your session expired. Please log in again.');
    }
    throw Exception(msg.isNotEmpty ? msg : 'Request failed ($status)');
  }

  /// `GET /jobs` — no auth. Uses `search`, `location`, `industry_type`, `company_id`,
  /// `published_after` (ISO date), `from_top_companies` (spotlight employers only when any exist), pagination.
  Future<List<Job>> listJobs({
    String? search,
    String? location,
    String? industryType,
    int? companyId,
    String? publishedAfter,
    bool fromTopCompanies = false,
    int page = 1,
    int perPage = 50,
  }) async {
    final uri = Uri.parse('$_base/jobs').replace(
      queryParameters: {
        'page': '$page',
        'per_page': '$perPage',
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (location != null && location.trim().isNotEmpty)
          'location': location.trim(),
        if (industryType != null && industryType.trim().isNotEmpty)
          'industry_type': industryType.trim(),
        if (companyId != null) 'company_id': '$companyId',
        if (publishedAfter != null && publishedAfter.isNotEmpty)
          'published_after': publishedAfter,
        if (fromTopCompanies) 'from_top_companies': '1',
      },
    );
    final r = await http.get(uri, headers: _publicHeaders);
    final json = _decode(r);
    _ensureSuccess(json, r.statusCode);
    final data = json['data'];
    if (data is! List) {
      return [];
    }
    return data
        .map((e) => Job.fromApi(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// `GET /jobs/{id}` — published job, no auth.
  Future<Job> getJob(String id) async {
    final r = await http.get(
      Uri.parse('$_base/jobs/$id'),
      headers: _publicHeaders,
    );
    final json = _decode(r);
    _ensureSuccess(json, r.statusCode);
    final data = json['data'];
    if (data is Map<String, dynamic>) {
      return Job.fromApi(data);
    }
    throw Exception('Invalid job response');
  }

  /// Active industry types for dropdowns (`GET /industry-types`, no auth).
  Future<List<IndustryTypeOption>> listActiveIndustryTypesFromApi() async {
    final r = await http.get(
      Uri.parse('$_base/industry-types'),
      headers: _publicHeaders,
    );
    final json = _decode(r);
    _ensureSuccess(json, r.statusCode);
    final data = json['data'];
    if (data is! List || data.isEmpty) {
      return List<IndustryTypeOption>.from(kIndustryTypes);
    }
    final parsed = <({int sort, IndustryTypeOption opt})>[];
    for (final e in data) {
      if (e is! Map) continue;
      final m = Map<String, dynamic>.from(e);
      final key = m['key']?.toString();
      final label = m['label']?.toString();
      if (key == null || key.isEmpty || label == null || label.isEmpty) continue;
      final sort = int.tryParse(m['sort_order']?.toString() ?? '') ?? 0;
      parsed.add((sort: sort, opt: IndustryTypeOption(key, label)));
    }
    if (parsed.isEmpty) {
      return List<IndustryTypeOption>.from(kIndustryTypes);
    }
    parsed.sort((a, b) {
      final c = a.sort.compareTo(b.sort);
      return c != 0 ? c : a.opt.label.compareTo(b.opt.label);
    });
    return parsed.map((e) => e.opt).toList();
  }

  /// Seeker dashboard “Popular categories” tiles (`GET /seeker-home-popular-categories`, no auth).
  Future<List<SeekerPopularCategory>> listSeekerHomePopularCategories() async {
    final r = await http.get(
      Uri.parse('$_base/seeker-home-popular-categories'),
      headers: _publicHeaders,
    );
    final json = _decode(r);
    _ensureSuccess(json, r.statusCode);
    final data = json['data'];
    if (data is! List) {
      return [];
    }
    return data
        .map((e) => SeekerPopularCategory.fromApi(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// `POST /job-seeker/activity/time` — report foreground seconds (batched by client).
  Future<void> reportTimeSpent(int seconds) async {
    if (seconds < 1 || seconds > 300) return;
    final r = await http.post(
      Uri.parse('$_base/job-seeker/activity/time'),
      headers: _authHeaders,
      body: jsonEncode({'seconds': seconds}),
    );
    final json = _decode(r);
    _ensureSuccess(json, r.statusCode);
  }

  /// `POST /job-seeker/jobs/{jobId}/apply`
  Future<void> apply(String jobId, {String? coverLetter}) async {
    final body = <String, dynamic>{};
    if (coverLetter != null && coverLetter.trim().isNotEmpty) {
      body['cover_letter'] = coverLetter.trim();
    }
    final r = await http.post(
      Uri.parse('$_base/job-seeker/jobs/$jobId/apply'),
      headers: _authHeaders,
      body: jsonEncode(body),
    );
    final json = _decode(r);
    _ensureSuccess(json, r.statusCode);
  }

  /// `GET /job-seeker/applications`
  Future<List<JobApplication>> listMyApplications({
    int page = 1,
    int perPage = 50,
  }) async {
    final uri = Uri.parse(
      '$_base/job-seeker/applications',
    ).replace(queryParameters: {'page': '$page', 'per_page': '$perPage'});
    final r = await http.get(uri, headers: _authHeaders);
    final json = _decode(r);
    _ensureSuccess(json, r.statusCode);
    final data = json['data'];
    if (data is! List) return [];
    return data
        .map((e) => JobApplication.fromApi(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// `DELETE /job-seeker/applications/{applicationId}` — withdraw while status
  /// is `applied` or `shortlisted` (refunds one application credit server-side).
  Future<void> withdrawApplication(String applicationId) async {
    final r = await http.delete(
      Uri.parse('$_base/job-seeker/applications/$applicationId'),
      headers: _authHeaders,
    );
    final json = _decode(r);
    _ensureSuccess(json, r.statusCode);
  }

  /// `PUT /job-seeker/profile`
  Future<Map<String, dynamic>> updateSeekerProfile(
    Map<String, dynamic> body,
  ) async {
    final r = await http.put(
      Uri.parse('$_base/job-seeker/profile'),
      headers: _authHeaders,
      body: jsonEncode(body),
    );
    final json = _decode(r);
    _ensureSuccess(json, r.statusCode);
    final data = json['data'];
    if (data is Map<String, dynamic>) return data;
    throw Exception('Invalid profile response');
  }

  /// `GET /job-seeker/profile` — package fields included.
  Future<Map<String, dynamic>> getSeekerProfile() async {
    final r = await http.get(
      Uri.parse('$_base/job-seeker/profile'),
      headers: _authHeaders,
    );
    final json = _decode(r);
    _ensureSuccess(json, r.statusCode);
    final data = json['data'];
    if (data is Map<String, dynamic>) return data;
    throw Exception('Invalid profile response');
  }

  /// `POST /job-seeker/profile/resume` — upload 1 PDF (re-upload overwrites the URL).
  Future<Map<String, dynamic>> uploadResumePdf(File file) async {
    final t = AppSession.token;
    if (t == null || t.isEmpty) {
      throw StateError('Not authenticated');
    }

    final uri = Uri.parse('$_base/job-seeker/profile/resume');
    final req = http.MultipartRequest('POST', uri);
    req.headers['Accept'] = 'application/json';
    req.headers['Authorization'] = 'Bearer $t';
    req.files.add(await http.MultipartFile.fromPath('resume', file.path));

    final streamed = await req.send();
    final r = await http.Response.fromStream(streamed);
    final json = _decode(r);
    _ensureSuccess(json, r.statusCode);
    final data = json['data'];
    if (data is Map<String, dynamic>) return data;
    throw Exception('Invalid resume upload response');
  }

  /// `GET /job-seeker/packages/purchases` — paginated activation history (server account).
  Future<Map<String, dynamic>> getPackagePurchases({
    int page = 1,
    int perPage = 20,
  }) async {
    final uri = Uri.parse(
      '$_base/job-seeker/packages/purchases',
    ).replace(queryParameters: {'page': '$page', 'per_page': '$perPage'});
    final r = await http.get(uri, headers: _authHeaders);
    final json = _decode(r);
    _ensureSuccess(json, r.statusCode);
    final data = json['data'];
    final list = <Map<String, dynamic>>[];
    if (data is List) {
      for (final e in data) {
        if (e is Map) list.add(Map<String, dynamic>.from(e));
      }
    }
    final meta = json['meta'];
    return {
      'items': list,
      'meta': meta is Map ? Map<String, dynamic>.from(meta) : null,
    };
  }

  /// `GET /job-seeker/packages/catalog`
  Future<List<Map<String, dynamic>>> getPackageCatalog() async {
    final r = await http.get(
      Uri.parse('$_base/job-seeker/packages/catalog'),
      headers: _authHeaders,
    );
    final json = _decode(r);
    _ensureSuccess(json, r.statusCode);
    final data = json['data'];
    if (data is! List) return [];
    return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// `GET /job-seeker/resume/drafts` — saved resumes + `primary_resume_draft_id`.
  Future<Map<String, dynamic>> getResumeDrafts() async {
    final r = await http.get(
      Uri.parse('$_base/job-seeker/resume/drafts'),
      headers: _authHeaders,
    );
    final json = _decode(r);
    _ensureSuccess(json, r.statusCode);
    final data = json['data'];
    if (data is Map<String, dynamic>) return data;
    throw Exception('Invalid resume drafts response');
  }

  /// `POST /job-seeker/resume/primary` — which draft employers see with applications.
  Future<Map<String, dynamic>> setPrimaryResumeDraft(int resumeDraftId) async {
    final r = await http.post(
      Uri.parse('$_base/job-seeker/resume/primary'),
      headers: _authHeaders,
      body: jsonEncode({'resume_draft_id': resumeDraftId}),
    );
    final json = _decode(r);
    _ensureSuccess(json, r.statusCode);
    final data = json['data'];
    if (data is Map<String, dynamic>) return data;
    throw Exception('Invalid response');
  }

  /// `POST /job-seeker/resume/pdf-purchase` — ₹20 demo; logs template for admin (PDF built on device).
  Future<Map<String, dynamic>> purchaseResumePdfExport({
    required int resumeTemplateId,
    required String resumeTemplateTitle,
  }) async {
    final r = await http.post(
      Uri.parse('$_base/job-seeker/resume/pdf-purchase'),
      headers: _authHeaders,
      body: jsonEncode({
        'resume_template_id': resumeTemplateId,
        'resume_template_title': resumeTemplateTitle,
      }),
    );
    final json = _decode(r);
    _ensureSuccess(json, r.statusCode);
    final data = json['data'];
    if (data is Map<String, dynamic>) return data;
    throw Exception('Invalid response');
  }

  /// `POST /job-seeker/resume/one-off-purchase` — one-time resume download (₹20 demo).
  Future<void> purchaseOneOffResume() async {
    final r = await http.post(
      Uri.parse('$_base/job-seeker/resume/one-off-purchase'),
      headers: _authHeaders,
    );
    final json = _decode(r);
    _ensureSuccess(json, r.statusCode);
  }

  /// `POST /job-seeker/packages/select` — activate without payment (placeholder).
  Future<Map<String, dynamic>> selectPackage(String packageKey) async {
    final r = await http.post(
      Uri.parse('$_base/job-seeker/packages/select'),
      headers: _authHeaders,
      body: jsonEncode({'package_key': packageKey}),
    );
    final json = _decode(r);
    _ensureSuccess(json, r.statusCode);
    final data = json['data'];
    if (data is Map<String, dynamic>) return data;
    throw Exception('Invalid response');
  }

  /// `POST /job-seeker/resume/ai-assist` — OpenRouter improves one section (no credits).
  Future<String> resumeAiAssist({
    required String sectionName,
    String? currentText,
    String? instruction,
    String? jobContext,
  }) async {
    final body = <String, dynamic>{
      'section_name': sectionName,
      'current_text': currentText ?? '',
      if (instruction != null && instruction.trim().isNotEmpty)
        'instruction': instruction.trim(),
      if (jobContext != null && jobContext.trim().isNotEmpty)
        'job_context': jobContext.trim(),
    };
    final r = await http.post(
      Uri.parse('$_base/job-seeker/resume/ai-assist'),
      headers: _authHeaders,
      body: jsonEncode(body),
    );
    final json = _decode(r);
    if (json['success'] != true) {
      throw Exception(
        json['message']?.toString() ?? 'Request failed (${r.statusCode})',
      );
    }
    final data = json['data'];
    if (data is Map && data['improved_text'] is String) {
      return data['improved_text'] as String;
    }
    throw Exception('Invalid AI response');
  }

  /// `POST /job-seeker/jobs/{jobId}/save` — save/bookmark a job
  Future<void> saveJob(String jobId) async {
    final r = await http.post(
      Uri.parse('$_base/job-seeker/jobs/$jobId/save'),
      headers: _authHeaders,
    );
    final json = _decode(r);
    _ensureSuccess(json, r.statusCode);
  }

  /// `DELETE /job-seeker/jobs/{jobId}/save` — remove bookmark
  Future<void> unsaveJob(String jobId) async {
    final r = await http.delete(
      Uri.parse('$_base/job-seeker/jobs/$jobId/save'),
      headers: _authHeaders,
    );
    final json = _decode(r);
    _ensureSuccess(json, r.statusCode);
  }

  /// `GET /job-seeker/saved-jobs` — list saved/bookmarked jobs
  Future<List<Job>> listSavedJobs({int page = 1, int perPage = 50}) async {
    final uri = Uri.parse(
      '$_base/job-seeker/saved-jobs',
    ).replace(queryParameters: {'page': '$page', 'per_page': '$perPage'});
    final r = await http.get(uri, headers: _authHeaders);
    final json = _decode(r);
    _ensureSuccess(json, r.statusCode);
    final data = json['data'];
    if (data is! List) return [];
    return data
        .map((e) => Job.fromApi(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// `GET /job-seeker/recommended-jobs` — get personalized job recommendations
  Future<List<Job>> getRecommendedJobs({int page = 1, int perPage = 50}) async {
    final uri = Uri.parse(
      '$_base/job-seeker/recommended-jobs',
    ).replace(queryParameters: {'page': '$page', 'per_page': '$perPage'});
    final r = await http.get(uri, headers: _authHeaders);
    final json = _decode(r);
    _ensureSuccess(json, r.statusCode);
    final data = json['data'];
    if (data is! List) return [];
    return data
        .map((e) => Job.fromApi(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// `GET /job-seeker/related-jobs` — jobs at companies / industries you applied to.
  Future<List<Job>> getRelatedJobs({int page = 1, int perPage = 15}) async {
    final uri = Uri.parse(
      '$_base/job-seeker/related-jobs',
    ).replace(queryParameters: {'page': '$page', 'per_page': '$perPage'});
    final r = await http.get(uri, headers: _authHeaders);
    final json = _decode(r);
    _ensureSuccess(json, r.statusCode);
    final data = json['data'];
    if (data is! List) return [];
    return data
        .map((e) => Job.fromApi(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// `GET /companies/top` — verified employers with open roles (public).
  Future<List<TopCompany>> getTopCompanies({int limit = 12}) async {
    final uri = Uri.parse('$_base/companies/top').replace(
      queryParameters: {'limit': '$limit'},
    );
    final r = await http.get(uri, headers: _publicHeaders);
    final json = _decode(r);
    _ensureSuccess(json, r.statusCode);
    final data = json['data'];
    if (data is! List) return [];
    return data
        .map((e) => TopCompany.fromApi(Map<String, dynamic>.from(e as Map)))
        .where((c) => c.id > 0)
        .toList();
  }

  /// `POST /job-seeker/career/ai-coach` — OpenRouter career path / interview prep.
  Future<Map<String, dynamic>> postCareerAiCoach({
    required String kind,
    String? focus,
  }) async {
    final body = <String, dynamic>{
      'kind': kind,
      if (focus != null && focus.trim().isNotEmpty) 'focus': focus.trim(),
    };
    final r = await http.post(
      Uri.parse('$_base/job-seeker/career/ai-coach'),
      headers: _authHeaders,
      body: jsonEncode(body),
    );
    final json = _decode(r);
    _ensureSuccess(json, r.statusCode);
    final data = json['data'];
    if (data is Map<String, dynamic>) return data;
    throw Exception('Invalid AI coach response');
  }

  /// `GET /job-seeker/career/contents?type=career_guidance|interview_experience|interview_qa`
  /// Returns `{ items: [...] }` or `{ categories: [...] }` for Q&A.
  Future<Map<String, dynamic>> getCareerContents(String type) async {
    final uri = Uri.parse('$_base/job-seeker/career/contents').replace(
      queryParameters: {'type': type},
    );
    final r = await http.get(uri, headers: _authHeaders);
    final json = _decode(r);
    _ensureSuccess(json, r.statusCode);
    final data = json['data'];
    if (data is Map<String, dynamic>) return data;
    throw Exception('Invalid career contents response');
  }

  /// `POST /job-seeker/career/contents/{id}/helpful`
  Future<Map<String, dynamic>> setCareerContentHelpful(
    int id, {
    required bool helpful,
  }) async {
    final r = await http.post(
      Uri.parse('$_base/job-seeker/career/contents/$id/helpful'),
      headers: _authHeaders,
      body: jsonEncode({'helpful': helpful}),
    );
    final json = _decode(r);
    _ensureSuccess(json, r.statusCode);
    final data = json['data'];
    if (data is Map<String, dynamic>) return data;
    throw Exception('Invalid helpful response');
  }

  /// `GET /job-seeker/feedback` — paginated entries for the signed-in seeker.
  Future<Map<String, dynamic>> listSeekerFeedback({
    int page = 1,
    int perPage = 20,
  }) async {
    final uri = Uri.parse('$_base/job-seeker/feedback').replace(
      queryParameters: {'page': '$page', 'per_page': '$perPage'},
    );
    final r = await http.get(uri, headers: _authHeaders);
    final json = _decode(r);
    _ensureSuccess(json, r.statusCode);
    final data = json['data'];
    final list = <Map<String, dynamic>>[];
    if (data is List) {
      for (final e in data) {
        if (e is Map) list.add(Map<String, dynamic>.from(e));
      }
    }
    final meta = json['meta'];
    return {
      'items': list,
      'meta': meta is Map ? Map<String, dynamic>.from(meta) : null,
    };
  }

  /// `POST /job-seeker/feedback`
  Future<Map<String, dynamic>> submitSeekerFeedback({
    required int rating,
    String? message,
  }) async {
    final body = <String, dynamic>{
      'rating': rating,
      if (message != null && message.trim().isNotEmpty) 'message': message.trim(),
    };
    final r = await http.post(
      Uri.parse('$_base/job-seeker/feedback'),
      headers: _authHeaders,
      body: jsonEncode(body),
    );
    final json = _decode(r);
    _ensureSuccess(json, r.statusCode);
    final data = json['data'];
    if (data is Map<String, dynamic>) return data;
    throw Exception('Invalid feedback response');
  }

  /// `GET /resume/demo-preview-html-batch` — all 12 templates HTML for one demo profile.
  Future<Map<String, String>> fetchDemoPreviewHtmlBatch(int demoVariant) async {
    final r = await http.get(
      Uri.parse('$_base/resume/demo-preview-html-batch?demo_variant=$demoVariant'),
      headers: _publicHeaders,
    );
    final json = _decode(r);
    _ensureSuccess(json, r.statusCode);
    final data = json['data'];
    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid demo preview batch response');
    }
    final raw = data['previews'];
    if (raw is! Map) return {};
    return raw.map((k, v) => MapEntry(k.toString(), v.toString()));
  }

  /// `GET /resume/demo-profiles` — Laravel `ResumeHtmlDemoData` (public).
  Future<List<ResumeDemoViewProfile>> fetchResumeDemoProfiles() async {
    final r = await http.get(
      Uri.parse('$_base/resume/demo-profiles'),
      headers: _publicHeaders,
    );
    final json = _decode(r);
    _ensureSuccess(json, r.statusCode);
    final data = json['data'];
    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid demo profiles response');
    }
    final raw = data['profiles'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => ResumeDemoViewProfile.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// `POST /job-seeker/resume/preview-html` — returns `{ html, template_key }`.
  Future<Map<String, dynamic>> resumePreviewHtml({
    required String templateKey,
    Map<String, dynamic>? contentEnvelope,
    int? resumeDraftId,
    int? demoVariant,
  }) async {
    final body = <String, dynamic>{
      'template_key': templateKey,
      if (contentEnvelope != null) 'content': contentEnvelope,
      if (resumeDraftId != null) 'resume_draft_id': resumeDraftId,
      if (demoVariant != null) 'demo_variant': demoVariant,
    };
    final r = await http.post(
      Uri.parse('$_base/job-seeker/resume/preview-html'),
      headers: _authHeaders,
      body: jsonEncode(body),
    );
    final json = _decode(r);
    _ensureSuccess(json, r.statusCode);
    final data = json['data'];
    if (data is Map<String, dynamic>) return data;
    throw Exception('Invalid preview response');
  }

  /// `POST /job-seeker/resume/save` — create or update a draft (`resume_draft_id` optional).
  Future<Map<String, dynamic>> saveResumeDraft({
    required String title,
    required String templateId,
    required Map<String, dynamic> contentEnvelope,
    int? resumeDraftId,
  }) async {
    final body = <String, dynamic>{
      'title': title,
      'template_id': templateId,
      'content': contentEnvelope,
      if (resumeDraftId != null) 'resume_draft_id': resumeDraftId,
    };
    final r = await http.post(
      Uri.parse('$_base/job-seeker/resume/save'),
      headers: _authHeaders,
      body: jsonEncode(body),
    );
    final json = _decode(r);
    _ensureSuccess(json, r.statusCode);
    final data = json['data'];
    if (data is Map<String, dynamic>) return data;
    throw Exception('Invalid resume save response');
  }
}
