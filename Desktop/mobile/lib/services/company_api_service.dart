import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../utils/api_json_decode.dart';
import 'app_session.dart';

/// Employer / company endpoints (`/api/v1/company/...`). Requires [AppSession.token] and company role.
class CompanyApiService {
  CompanyApiService._();
  static final CompanyApiService instance = CompanyApiService._();

  String get _base => ApiConfig.baseUrl;

  Map<String, String> get _headers {
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

  /// GET /company/profile
  Future<Map<String, dynamic>> getProfile() async {
    final r = await http.get(Uri.parse('$_base/company/profile'), headers: _headers);
    final json = _decode(r);
    _ensureSuccess(json, r.statusCode);
    final data = json['data'];
    if (data is Map<String, dynamic>) return data;
    throw Exception('Invalid profile response');
  }

  /// PUT /company/profile
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> body) async {
    final r = await http.put(
      Uri.parse('$_base/company/profile'),
      headers: _headers,
      body: jsonEncode(body),
    );
    final json = _decode(r);
    _ensureSuccess(json, r.statusCode);
    final data = json['data'];
    if (data is Map<String, dynamic>) return data;
    throw Exception('Invalid response');
  }

  /// GET /company/job-posts — returns `{'items': [...], 'meta': {...}}`.
  Future<Map<String, dynamic>> listJobPosts({
    int page = 1,
    int perPage = 50,
  }) async {
    final uri = Uri.parse('$_base/company/job-posts').replace(
      queryParameters: {'page': '$page', 'per_page': '$perPage'},
    );
    final r = await http.get(uri, headers: _headers);
    final json = _decode(r);
    _ensureSuccess(json, r.statusCode);
    final data = json['data'];
    final meta = json['meta'];
    final list = <Map<String, dynamic>>[];
    if (data is List) {
      for (final e in data) {
        if (e is Map<String, dynamic>) list.add(e);
      }
    }
    return {
      'items': list,
      'meta': meta is Map<String, dynamic> ? meta : null,
    };
  }

  /// POST /company/job-posts
  Future<Map<String, dynamic>> createJobPost(Map<String, dynamic> body) async {
    final r = await http.post(
      Uri.parse('$_base/company/job-posts'),
      headers: _headers,
      body: jsonEncode(body),
    );
    final json = _decode(r);
    _ensureSuccess(json, r.statusCode);
    final data = json['data'];
    if (data is Map<String, dynamic>) return data;
    throw Exception('Invalid response');
  }

  /// PUT /company/job-posts/{id} — update fields, or send `{ "status": "closed" }` to close the posting.
  Future<Map<String, dynamic>> updateJobPost(
    int id,
    Map<String, dynamic> body,
  ) async {
    final r = await http.put(
      Uri.parse('$_base/company/job-posts/$id'),
      headers: _headers,
      body: jsonEncode(body),
    );
    final json = _decode(r);
    _ensureSuccess(json, r.statusCode);
    final data = json['data'];
    if (data is Map<String, dynamic>) return data;
    throw Exception('Invalid response');
  }

  /// GET /company/job-posts/{jobId}/applications — returns `{'items': [...], 'total': n}`.
  Future<Map<String, dynamic>> listApplications(
    int jobId, {
    int page = 1,
    int perPage = 50,
  }) async {
    final uri = Uri.parse('$_base/company/job-posts/$jobId/applications').replace(
      queryParameters: {'page': '$page', 'per_page': '$perPage'},
    );
    final r = await http.get(uri, headers: _headers);
    final json = _decode(r);
    _ensureSuccess(json, r.statusCode);
    final data = json['data'];
    final meta = json['meta'];
    final list = <Map<String, dynamic>>[];
    if (data is List) {
      for (final e in data) {
        if (e is Map<String, dynamic>) list.add(e);
      }
    }
    var total = list.length;
    if (meta is Map && meta['total'] != null) {
      total = int.tryParse(meta['total'].toString()) ?? total;
    }
    return {'items': list, 'total': total};
  }

  /// PATCH /company/job-posts/{jobId}/applications/{applicationId}
  Future<Map<String, dynamic>> updateApplicationStatus(
    int jobId,
    int applicationId, {
    required String status,
    String? employerNote,
  }) async {
    final body = <String, dynamic>{
      'status': status,
      'employer_note': employerNote,
    };
    final r = await http.patch(
      Uri.parse('$_base/company/job-posts/$jobId/applications/$applicationId'),
      headers: _headers,
      body: jsonEncode(body),
    );
    final json = _decode(r);
    _ensureSuccess(json, r.statusCode);
    final data = json['data'];
    if (data is Map<String, dynamic>) return data;
    throw Exception('Invalid response');
  }
}
