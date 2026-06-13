import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

/// True when the body looks like HTML (common when the API URL is wrong or the
/// server returns nginx/Apache/Laravel error pages instead of JSON).
bool responseBodyLooksLikeHtml(String body) {
  final t = body.trimLeft();
  if (t.isEmpty) return false;
  if (t.startsWith(RegExp(r'<!DOCTYPE', caseSensitive: false))) return true;
  if (t.startsWith(RegExp(r'<html', caseSensitive: false))) return true;
  // Many error pages start with `<` but JSON never does for our APIs.
  if (t.length > 2 && t[0] == '<' && !t.startsWith('{') && !t.startsWith('[')) {
    return true;
  }
  return false;
}

/// Decodes a JSON object from an HTTP response, with a clear error if the server
/// sent HTML (wrong base URL, 404 page, PHP error page, etc.).
Map<String, dynamic> decodeApiJsonObject(http.Response response) {
  final url = response.request?.url.toString() ?? '(unknown URL)';
  final body = response.body;

  if (responseBodyLooksLikeHtml(body)) {
    final redirectHint = (response.statusCode == 301 || response.statusCode == 302)
        ? '• Live server: use https:// in API_BASE_URL (http often 301-redirects).\n'
        : '';
    throw Exception(
      'Server returned a web page instead of JSON (HTTP ${response.statusCode}). '
      'The app is probably not pointing at your Laravel API.\n\n'
      'Fix:\n'
      '$redirectHint'
      '• Local dev: php artisan serve (port 8000)\n'
      '• Android emulator: flutter run '
      '--dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1\n'
      '• Physical phone: use your PC IP, e.g. '
      '--dart-define=API_BASE_URL=http://192.168.0.5:8000/api/v1\n\n'
      'Request: $url\n'
      'Configured API base: ${ApiConfig.baseUrl}',
    );
  }

  try {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }
    throw Exception('Expected JSON object, got ${decoded.runtimeType}');
  } on FormatException catch (e) {
    throw Exception(
      'Invalid JSON from server (HTTP ${response.statusCode}): ${e.message}\nURL: $url',
    );
  }
}
