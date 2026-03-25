import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/job.dart';
import '../utils/api_json_decode.dart';
import 'app_session.dart';

/// Public job board + authenticated seeker actions (`/api/v1/jobs`, `/job-seeker/...`).
class JobSeekerApiService {
  JobSeekerApiService._();
  static final JobSeekerApiService instance = JobSeekerApiService._();

  String get _base => ApiConfig.baseUrl;

  Map<String, String> get _publicHeaders => {
        'Accept': 'application/json',
      };

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
    throw Exception(json['message']?.toString() ?? 'Request failed ($status)');
  }

  /// `GET /jobs` — no auth. Uses `search`, `location`, `industry_type`, pagination.
  Future<List<Job>> listJobs({
    String? search,
    String? location,
    String? industryType,
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
  Future<Job> getJob(int id) async {
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

  /// `POST /job-seeker/jobs/{jobId}/apply`
  Future<void> apply(
    int jobId, {
    String? coverLetter,
  }) async {
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
    final uri = Uri.parse('$_base/job-seeker/applications').replace(
      queryParameters: {'page': '$page', 'per_page': '$perPage'},
    );
    final r = await http.get(uri, headers: _authHeaders);
    final json = _decode(r);
    _ensureSuccess(json, r.statusCode);
    final data = json['data'];
    if (data is! List) return [];
    return data
        .map((e) =>
            JobApplication.fromApi(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// `DELETE /job-seeker/applications/{applicationId}` — withdraw while status
  /// is `applied` or `shortlisted` (refunds one application credit server-side).
  Future<void> withdrawApplication(int applicationId) async {
    final r = await http.delete(
      Uri.parse('$_base/job-seeker/applications/$applicationId'),
      headers: _authHeaders,
    );
    final json = _decode(r);
    _ensureSuccess(json, r.statusCode);
  }

  /// `PUT /job-seeker/profile`
  Future<Map<String, dynamic>> updateSeekerProfile(
      Map<String, dynamic> body) async {
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

  /// `GET /job-seeker/packages/purchases` — paginated activation history (server account).
  Future<Map<String, dynamic>> getPackagePurchases({
    int page = 1,
    int perPage = 20,
  }) async {
    final uri = Uri.parse('$_base/job-seeker/packages/purchases').replace(
      queryParameters: {
        'page': '$page',
        'per_page': '$perPage',
      },
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
      'meta': meta is Map ? Map<String, dynamic>.from(meta as Map) : null,
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
    return data
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
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

  /// `POST /job-seeker/resume/one-off-purchase` — ₹20 demo payment, +1 resume build (when no plan credits).
  Future<Map<String, dynamic>> purchaseOneOffResume() async {
    final r = await http.post(
      Uri.parse('$_base/job-seeker/resume/one-off-purchase'),
      headers: _authHeaders,
    );
    final json = _decode(r);
    _ensureSuccess(json, r.statusCode);
    final data = json['data'];
    if (data is Map<String, dynamic>) return data;
    throw Exception('Invalid response');
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

  /// `POST /job-seeker/resume/ai-assist` — OpenRouter improves one section; uses one resume credit.
  Future<String> resumeAiAssist({
    required String sectionName,
    String? currentText,
    String? instruction,
    String? jobContext,
  }) async {
    final body = <String, dynamic>{
      'section_name': sectionName,
      if (currentText != null && currentText.trim().isNotEmpty)
        'current_text': currentText,
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
      throw Exception(json['message']?.toString() ?? 'Request failed (${r.statusCode})');
    }
    final data = json['data'];
    if (data is Map && data['improved_text'] is String) {
      return data['improved_text'] as String;
    }
    throw Exception('Invalid AI response');
  }

  /// `POST /job-seeker/jobs/{jobId}/save` — save/bookmark a job
  Future<void> saveJob(int jobId) async {
    final r = await http.post(
      Uri.parse('$_base/job-seeker/jobs/$jobId/save'),
      headers: _authHeaders,
    );
    final json = _decode(r);
    _ensureSuccess(json, r.statusCode);
  }

  /// `DELETE /job-seeker/jobs/{jobId}/save` — remove bookmark
  Future<void> unsaveJob(int jobId) async {
    final r = await http.delete(
      Uri.parse('$_base/job-seeker/jobs/$jobId/save'),
      headers: _authHeaders,
    );
    final json = _decode(r);
    _ensureSuccess(json, r.statusCode);
  }

  /// `GET /job-seeker/saved-jobs` — list saved/bookmarked jobs
  Future<List<Job>> listSavedJobs({
    int page = 1,
    int perPage = 50,
  }) async {
    final uri = Uri.parse('$_base/job-seeker/saved-jobs').replace(
      queryParameters: {
        'page': '$page',
        'per_page': '$perPage',
      },
    );
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
  Future<List<Job>> getRecommendedJobs({
    int page = 1,
    int perPage = 50,
  }) async {
    final uri = Uri.parse('$_base/job-seeker/recommended-jobs').replace(
      queryParameters: {
        'page': '$page',
        'per_page': '$perPage',
      },
    );
    final r = await http.get(uri, headers: _authHeaders);
    final json = _decode(r);
    _ensureSuccess(json, r.statusCode);
    final data = json['data'];
    if (data is! List) return [];
    return data
        .map((e) => Job.fromApi(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}
