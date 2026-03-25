import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Auth session + persistent storage (survives app restarts).
class AppSession {
  AppSession._();

  static const _kToken = 'app_session_token';
  static const _kUserJson = 'app_session_user_json';

  static String? token;
  static String? userId;
  static Map<String, dynamic>? user;

  static bool get isLoggedIn => token != null && token!.isNotEmpty;

  /// Call once at startup (see [main.dart]) before [runApp].
  static Future<void> loadFromStorage() async {
    try {
      final p = await SharedPreferences.getInstance();
      final t = p.getString(_kToken);
      final u = p.getString(_kUserJson);
      if (t == null || t.isEmpty || u == null || u.isEmpty) {
        _clearMemoryOnly();
        return;
      }
      final decoded = jsonDecode(u);
      if (decoded is! Map<String, dynamic>) {
        await _clearPrefs(p);
        _clearMemoryOnly();
        return;
      }
      token = t;
      user = Map<String, dynamic>.from(decoded);
      final id = user!['id'];
      userId = id == null ? null : id.toString();
    } catch (_) {
      _clearMemoryOnly();
      final p = await SharedPreferences.getInstance();
      await _clearPrefs(p);
    }
  }

  static void setSession({
    required String bearerToken,
    required Map<String, dynamic> userPayload,
  }) {
    token = bearerToken;
    user = Map<String, dynamic>.from(userPayload);
    final id = userPayload['id'];
    userId = id == null ? null : id.toString();
    // Persist without blocking UI
    persist().catchError((_) {});
  }

  /// Remove session from memory and device storage.
  static Future<void> clear() async {
    _clearMemoryOnly();
    try {
      final p = await SharedPreferences.getInstance();
      await _clearPrefs(p);
    } catch (_) {}
  }

  static void _clearMemoryOnly() {
    token = null;
    userId = null;
    user = null;
  }

  static Future<void> _clearPrefs(SharedPreferences p) async {
    await p.remove(_kToken);
    await p.remove(_kUserJson);
  }

  static Future<void> persist() async {
    final p = await SharedPreferences.getInstance();
    if (token == null || token!.isEmpty) {
      await _clearPrefs(p);
      return;
    }
    await p.setString(_kToken, token!);
    if (user != null) {
      await p.setString(_kUserJson, jsonEncode(user));
    }
  }
}
