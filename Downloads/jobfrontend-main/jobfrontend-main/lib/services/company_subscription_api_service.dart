import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../utils/api_json_decode.dart';
import 'app_session.dart';

class CompanySubscriptionApiService {
  CompanySubscriptionApiService._();
  static final CompanySubscriptionApiService instance =
      CompanySubscriptionApiService._();

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

  /// GET /api/v1/company/subscription/offer
  Future<Map<String, dynamic>> getOffer() async {
    final r = await http.get(
      Uri.parse('$_base/company/subscription/offer'),
      headers: _headers,
    );

    final json = _decode(r);
    _ensureSuccess(json, r.statusCode);

    final data = json['data'];
    if (data is Map<String, dynamic>) return data;
    return <String, dynamic>{};
  }

  /// POST /api/v1/company/subscription/purchase
  Future<Map<String, dynamic>> purchase({String? couponCode}) async {
    final r = await http.post(
      Uri.parse('$_base/company/subscription/purchase'),
      headers: _headers,
      body: jsonEncode({
        if (couponCode != null && couponCode.trim().isNotEmpty)
          'coupon_code': couponCode.trim(),
      }),
    );

    final json = _decode(r);
    _ensureSuccess(json, r.statusCode);

    final data = json['data'];
    if (data is Map<String, dynamic>) return data;
    return <String, dynamic>{};
  }

  /// GET /api/v1/company/subscription/history
  Future<List<Map<String, dynamic>>> history() async {
    final r = await http.get(
      Uri.parse('$_base/company/subscription/history'),
      headers: _headers,
    );

    final json = _decode(r);
    _ensureSuccess(json, r.statusCode);

    final items = json['data']?['items'];
    if (items is List) {
      return items.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }
}
