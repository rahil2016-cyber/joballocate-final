import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/media_url.dart';

/// Auth session + persistent storage (survives app restarts).
class AppSession {
  AppSession._();

  static const _kToken = 'app_session_token';
  static const _kUserJson = 'app_session_user_json';
  /// Backup for routing when [user] JSON omits `role` (e.g. older API clients).
  static const _kPersistedRole = 'app_session_persisted_role';

  static String? token;
  static String? userId;
  static Map<String, dynamic>? user;

  /// Global notifier for profile photo updates so UI can sync everywhere.
  static final profilePhotoNotifier = ValueNotifier<String?>(null);
  static final companyLogoNotifier = ValueNotifier<String?>(null);

  /// Updates the cached user object and notifies photo listeners if URL changed.
  static void updateUser(Map<String, dynamic> newUser) {
    user = Map<String, dynamic>.from(newUser);
    final photo = user?['profile_photo_url']?.toString().trim() ??
        user?['profile_photo']?.toString().trim() ?? '';
    profilePhotoNotifier.value = MediaUrl.resolve(photo);
    persist().catchError((_) {});
  }

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
      if (decoded is! Map) {
        await _clearPrefs(p);
        _clearMemoryOnly();
        return;
      }
      token = t;
      user = Map<String, dynamic>.from(decoded);
      final photo = user?['profile_photo_url']?.toString().trim() ??
          user?['profile_photo']?.toString().trim() ?? '';
      profilePhotoNotifier.value = MediaUrl.resolve(photo);
      userId = user!['id']?.toString();
      final persistedRole = p.getString(_kPersistedRole);
      final r = user!['role']?.toString().trim();
      if ((r == null || r.isEmpty) &&
          persistedRole != null &&
          persistedRole.isNotEmpty) {
        user!['role'] = persistedRole;
      }
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
    updateUser(userPayload);
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
    await p.remove(_kPersistedRole);
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
      final role = user!['role']?.toString().trim();
      if (role != null && role.isNotEmpty) {
        await p.setString(_kPersistedRole, role);
      }
    }
  }
}
