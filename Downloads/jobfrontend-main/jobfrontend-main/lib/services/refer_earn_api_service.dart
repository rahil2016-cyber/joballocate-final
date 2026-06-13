import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../utils/api_json_decode.dart';
import 'app_session.dart';

/// Refer & earn settings and promo validation (`/refer-earn`).
class ReferEarnApiService {
  ReferEarnApiService._();
  static final ReferEarnApiService instance = ReferEarnApiService._();

  String get _base => ApiConfig.baseUrl;

  Map<String, String> get _headers {
    final h = <String, String>{'Accept': 'application/json'};
    final t = AppSession.token;
    if (t != null && t.isNotEmpty) {
      h['Authorization'] = 'Bearer $t';
    }
    return h;
  }

  Map<String, dynamic> _decode(http.Response r) => decodeApiJsonObject(r);

  void _ensureOk(Map<String, dynamic> json, int status) {
    if (status >= 200 && status < 300 && json['success'] == true) return;
    throw Exception(json['message']?.toString() ?? 'Request failed ($status)');
  }

  /// `audience`: `job_seeker` or `company`
  Future<Map<String, dynamic>> fetchReferEarn({required String audience}) async {
    final uri = Uri.parse('$_base/refer-earn').replace(
      queryParameters: {'audience': audience},
    );
    final r = await http.get(uri, headers: _headers);
    final json = _decode(r);
    _ensureOk(json, r.statusCode);
    final data = json['data'];
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw Exception('Invalid refer-earn response');
  }

  Future<Map<String, dynamic>> validateReferralCode({
    required String code,
    required String audience,
  }) async {
    final r = await http.post(
      Uri.parse('$_base/refer-earn/validate'),
      headers: {..._headers, 'Content-Type': 'application/json'},
      body: jsonEncode({'code': code.trim(), 'audience': audience}),
    );
    final json = _decode(r);
    _ensureOk(json, r.statusCode);
    final data = json['data'];
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw Exception('Invalid validation response');
  }
}
