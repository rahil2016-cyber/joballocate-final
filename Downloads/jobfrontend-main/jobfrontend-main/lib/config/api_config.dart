import 'package:flutter/foundation.dart';

/// Backend base URL for REST API calls (`/api/v1`).
///
/// **Default:** production — [liveProductionBase] (`https://joballocate.tech/api/v1`).
///
/// **Local Laravel:** pass at build/run time:
/// `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1` (Android emulator)
/// or `http://127.0.0.1:8000/api/v1` (desktop/iOS simulator), or your PC LAN IP on a physical device.
class ApiConfig {
  ApiConfig._();

  /// Production API (Laravel). Use **HTTPS** so the server does not 301-redirect
  /// API calls to HTML (which breaks JSON parsing).
  ///
  /// Live backend: [joballocate.tech](https://joballocate.tech/api/v1).
  static const String liveProductionBase =
      'https://joballocate.tech/api/v1';

  /// Override via: `flutter run --dart-define=API_BASE_URL=https://.../api/v1`
  static const String _fromEnv = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static String? _resolved;
  static bool _initialized = false;

  /// How the base URL was chosen: `dart-define` or `live`.
  static String resolutionSource = 'pending';

  /// Call once from [main] before [runApp]. Required so [baseUrl] is stable.
  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    // Force connection to the live production server as requested
    _resolved = liveProductionBase;
    resolutionSource = 'live';
    debugPrint('[ApiConfig] Forced live production API → $liveProductionBase');
  }

  static String _normalizeBase(String u) =>
      u.endsWith('/') ? u.substring(0, u.length - 1) : u;

  /// Resolved after [initialize]. Before init, prefers dart-define then production.
  static String get baseUrl {
    return liveProductionBase;
  }
}
