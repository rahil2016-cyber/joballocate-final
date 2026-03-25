import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

bool _probeResponseLooksLikeHtml(String body) {
  final t = body.trimLeft();
  if (t.isEmpty) return false;
  if (t.startsWith(RegExp(r'<!DOCTYPE', caseSensitive: false))) return true;
  if (t.length > 2 && t[0] == '<' && !t.startsWith('{') && !t.startsWith('[')) {
    return true;
  }
  return false;
}

/// Backend base URL for REST API calls (`/api/v1`).
///
/// **APK / production testing (default):** On startup we try the **live** server
/// first; if it does not respond in time, we fall back to **local** Laravel.
///
/// **Override (always wins):** `flutter run --dart-define=API_BASE_URL=https://.../api/v1`
///
/// **Local dev:** Emulator uses `10.0.2.2:8000`, iOS simulator / desktop uses
/// `127.0.0.1:8000`. Physical devices need `--dart-define` with your PC LAN IP
/// when testing against a machine on the same Wi‑Fi.
class ApiConfig {
  ApiConfig._();

  /// Production API (Laravel). Use **HTTPS** so the server does not 301-redirect
  /// API calls to HTML (which breaks JSON parsing).
  static const String liveProductionBase =
      'https://demo.covalinx.in/api/v1';

  /// Override via: `flutter run --dart-define=API_BASE_URL=https://.../api/v1`
  static const String _fromEnv = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static const int _localPort = 8000;

  /// How long to wait for the live server before using localhost (emulator/simulator).
  static const Duration _probeTimeout = Duration(seconds: 6);

  static String? _resolved;
  static bool _initialized = false;

  /// How the base URL was chosen: `dart-define`, `live`, or `local`.
  static String resolutionSource = 'pending';

  /// Call once from [main] before [runApp]. Required so [baseUrl] is stable.
  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    if (_fromEnv.isNotEmpty) {
      _resolved = _normalizeBase(_fromEnv);
      resolutionSource = 'dart-define';
      debugPrint('[ApiConfig] Using API_BASE_URL override: $_resolved');
      return;
    }

    final local = _localDefault();
    try {
      final uri = Uri.parse('$liveProductionBase/jobs').replace(
        queryParameters: const {'page': '1', 'per_page': '1'},
      );
      final r = await http
          .get(
            uri,
            headers: const {'Accept': 'application/json'},
          )
          .timeout(_probeTimeout);

      // Must look like JSON (Laravel API), not an HTML landing page or 404 page.
      if (r.statusCode < 600 && !_probeResponseLooksLikeHtml(r.body)) {
        try {
          final j = jsonDecode(r.body);
          if (j is Map && (j['success'] == true || j.containsKey('data'))) {
            _resolved = liveProductionBase;
            resolutionSource = 'live';
            debugPrint('[ApiConfig] Live API reachable → $liveProductionBase');
            return;
          }
        } catch (_) {
          // Not JSON — fall through to local.
        }
        debugPrint(
          '[ApiConfig] Live host responded but not JSON API; using local dev URL.',
        );
      }
    } catch (e, st) {
      debugPrint(
        '[ApiConfig] Live API probe failed ($e), using local dev URL. $st',
      );
    }

    _resolved = local;
    resolutionSource = 'local';
    debugPrint('[ApiConfig] Using local API → $local');
  }

  static String _normalizeBase(String u) =>
      u.endsWith('/') ? u.substring(0, u.length - 1) : u;

  static String _localDefault() {
    final host = Platform.isAndroid ? '10.0.2.2' : '127.0.0.1';
    return 'http://$host:$_localPort/api/v1';
  }

  /// Resolved after [initialize]. Before init, falls back to dart-define or local.
  static String get baseUrl {
    if (_resolved != null) return _resolved!;
    if (_fromEnv.isNotEmpty) return _normalizeBase(_fromEnv);
    return _localDefault();
  }
}
