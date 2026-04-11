import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/theme_provider.dart';

class PrefsService {
  static const _keyUsername = 'saved_username';
  static const _keyPassword = 'saved_password';
  static const _keyRememberMe = 'remember_me';
  static const _keyThemeMode = 'theme_mode';
  static const _keyThemeSource = 'theme_source';
  static const _keyPersistedSessionJson = 'persisted_session_json';
  static const _keySessionStartedMs = 'session_started_ms';

  /// Server token lifetime — session is invalid after this from login time.
  static const Duration sessionMaxAge = Duration(minutes: 10);

  late final SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // --- Credentials ---

  bool get rememberMe => _prefs.getBool(_keyRememberMe) ?? false;

  String? get savedUsername => _prefs.getString(_keyUsername);
  String? get savedPassword {
    final encoded = _prefs.getString(_keyPassword);
    if (encoded == null) return null;
    try {
      return utf8.decode(base64Decode(encoded));
    } catch (_) {
      return null;
    }
  }

  Future<void> saveCredentials(String username, String password) async {
    await _prefs.setBool(_keyRememberMe, true);
    await _prefs.setString(_keyUsername, username);
    await _prefs.setString(_keyPassword, base64Encode(utf8.encode(password)));
  }

  Future<void> clearCredentials() async {
    await _prefs.setBool(_keyRememberMe, false);
    await _prefs.remove(_keyUsername);
    await _prefs.remove(_keyPassword);
  }

  // --- Theme ---

  ThemeMode get themeMode {
    final value = _prefs.getString(_keyThemeMode);
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _prefs.setString(_keyThemeMode, mode.name);
  }

  ThemeSource get themeSource {
    final value = _prefs.getString(_keyThemeSource);
    switch (value) {
      case 'defaultSeed':
        return ThemeSource.defaultSeed;
      default:
        return ThemeSource.dynamic;
    }
  }

  Future<void> setThemeSource(ThemeSource source) async {
    await _prefs.setString(_keyThemeSource, source.name);
  }

  // --- Persisted auth session (survives app restart until [sessionMaxAge]) ---

  Future<void> savePersistedSession(Map<String, dynamic> loginData) async {
    await _prefs.setString(_keyPersistedSessionJson, jsonEncode(loginData));
    await _prefs.setInt(
        _keySessionStartedMs, DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> clearPersistedSession() async {
    await _prefs.remove(_keyPersistedSessionJson);
    await _prefs.remove(_keySessionStartedMs);
  }

  /// Returns login JSON if a session was saved and is still within [sessionMaxAge].
  /// Clears stored session if expired or invalid.
  Future<Map<String, dynamic>?> loadPersistedSessionIfValid() async {
    final jsonStr = _prefs.getString(_keyPersistedSessionJson);
    final ms = _prefs.getInt(_keySessionStartedMs);
    if (jsonStr == null || ms == null) return null;

    final started = DateTime.fromMillisecondsSinceEpoch(ms);
    if (DateTime.now().difference(started) > sessionMaxAge) {
      await clearPersistedSession();
      return null;
    }

    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    await clearPersistedSession();
    return null;
  }
}
