import '../config/api_config.dart';

/// Turns relative storage paths from Laravel (`/storage/...`) into a full URL
/// using the same host as [ApiConfig.baseUrl] (`…/api/v1` → origin).
class MediaUrl {
  MediaUrl._();

  static String apiOrigin() {
    final base = ApiConfig.baseUrl;
    if (base.endsWith('/api/v1')) {
      return base.substring(0, base.length - '/api/v1'.length);
    }
    if (base.endsWith('/api/v1/')) {
      return base.substring(0, base.length - '/api/v1/'.length);
    }
    final u = Uri.parse(base);
    return '${u.scheme}://${u.host}${u.hasPort ? ':${u.port}' : ''}';
  }

  static bool _isLoopbackHost(String host) {
    final h = host.toLowerCase();
    return h == 'localhost' ||
        h == '127.0.0.1' ||
        h == '0.0.0.0' ||
        h == '::1' ||
        h == '[::1]';
  }

  /// Laravel [asset()] often uses [APP_URL] (`http://127.0.0.1:8000`). The app
  /// talks to the API via `10.0.2.2` (emulator) or a LAN IP — same loopback URL
  /// fails in [Image.network] and falls back to initials. Rewrite to [apiOrigin].
  static String rewriteLoopbackToApiOrigin(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
      return url;
    }
    if (!_isLoopbackHost(uri.host)) return url;

    final o = Uri.parse(apiOrigin());
    if (!o.hasScheme || o.host.isEmpty) return url;

    return uri
        .replace(
          scheme: o.scheme,
          host: o.host,
          port: o.hasPort ? o.port : null,
        )
        .toString();
  }

  /// Hosts often return 403 for `/storage/*`; Laravel serves the same files at `/media/...`.
  static String rewriteBlockedStorageToMediaRoute(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return url;
    final path = uri.path;
    String? newPath;
    const profile = '/storage/profile-photos/';
    const logos = '/storage/company-logos/';
    if (path.startsWith(profile)) {
      final file = path.substring(profile.length);
      if (file.isNotEmpty &&
          !file.contains('..') &&
          !file.contains('/') &&
          RegExp(r'^[a-zA-Z0-9._-]+$').hasMatch(file)) {
        newPath = '/media/profile-photos/$file';
      }
    } else if (path.startsWith(logos)) {
      final file = path.substring(logos.length);
      if (file.isNotEmpty &&
          !file.contains('..') &&
          !file.contains('/') &&
          RegExp(r'^[a-zA-Z0-9._-]+$').hasMatch(file)) {
        newPath = '/media/company-logos/$file';
      }
    }
    if (newPath == null) return url;
    return uri.replace(path: newPath).toString();
  }

  /// Returns a string safe for [Image.network], or null.
  static String? resolve(String? raw) {
    if (raw == null) return null;
    final t = raw.trim();
    if (t.isEmpty) return null;
    String out;
    if (t.startsWith('https://') || t.startsWith('http://')) {
      out = rewriteLoopbackToApiOrigin(t);
    } else if (t.startsWith('//')) {
      out = rewriteLoopbackToApiOrigin('https:$t');
    } else if (t.startsWith('/')) {
      final origin = apiOrigin().replaceAll(RegExp(r'/$'), '');
      out = '$origin$t';
    } else if (t.startsWith('storage/')) {
      final origin = apiOrigin().replaceAll(RegExp(r'/$'), '');
      out = '$origin/$t';
    } else {
      out = t;
    }
    return rewriteBlockedStorageToMediaRoute(out);
  }
}
