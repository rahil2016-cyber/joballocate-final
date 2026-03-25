import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/banner.dart';
import '../utils/api_json_decode.dart';

/// Banner service for managing promotional banners shown on the platform.
/// Banners can be managed by admin and displayed to job seekers and employers.
class BannerApiService {
  BannerApiService._();
  static final BannerApiService instance = BannerApiService._();

  String get _base => ApiConfig.baseUrl;

  Map<String, String> get _publicHeaders => {
        'Accept': 'application/json',
      };

  Map<String, dynamic> _decode(http.Response r) => decodeApiJsonObject(r);

  void _ensureSuccess(Map<String, dynamic> json, int status) {
    if (status >= 200 && status < 300 && json['success'] == true) return;
    throw Exception(json['message']?.toString() ?? 'Request failed ($status)');
  }

  /// `GET /banners` — public, get all active banners
  Future<List<PromoBanner>> getActiveBanners() async {
    try {
      final uri = Uri.parse('$_base/banners').replace(
        queryParameters: {
          'is_active': 'true',
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
          .map((e) => PromoBanner.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      // Return empty list if API fails
      print('Banner fetch error: $e');
      return [];
    }
  }

  /// `GET /banners/{id}` — get specific banner
  Future<PromoBanner?> getBanner(String id) async {
    try {
      final r = await http.get(
        Uri.parse('$_base/banners/$id'),
        headers: _publicHeaders,
      );
      final json = _decode(r);
      _ensureSuccess(json, r.statusCode);
      
      final data = json['data'];
      if (data is Map<String, dynamic>) {
        return PromoBanner.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Banner fetch error: $e');
      return null;
    }
  }
}
