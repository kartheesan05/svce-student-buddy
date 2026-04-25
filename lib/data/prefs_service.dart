import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/theme_provider.dart';

class PrefsService {
  static const _keyUsername = 'saved_username';
  static const _keyPassword = 'saved_password';
  static const _keyRememberMe = 'remember_me';
  static const _keyThemeMode = 'theme_mode';
  static const _keyThemeSource = 'theme_source';
  static const _keyPersistedSessionJson = 'persisted_session_json';
  static const _keyAppSnapshotJson = 'app_snapshot_json';
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  late final SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _migrateLegacySensitiveData();
  }

  // --- Credentials ---

  bool get rememberMe => _prefs.getBool(_keyRememberMe) ?? true;

  Future<void> setRememberMe(bool value) async {
    await _prefs.setBool(_keyRememberMe, value);
  }

  Future<String?> getSavedUsername() async {
    return _secureStorage.read(key: _keyUsername);
  }

  Future<String?> getSavedPassword() async {
    return _secureStorage.read(key: _keyPassword);
  }

  Future<void> saveCredentials(String username, String password) async {
    await _secureStorage.write(key: _keyUsername, value: username);
    await _secureStorage.write(key: _keyPassword, value: password);
  }

  Future<void> clearCredentials() async {
    await _prefs.setBool(_keyRememberMe, false);
    await _prefs.remove(_keyUsername);
    await _prefs.remove(_keyPassword);
    await _secureStorage.delete(key: _keyUsername);
    await _secureStorage.delete(key: _keyPassword);
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

  // --- Persisted auth session ---

  Future<void> savePersistedSession(Map<String, dynamic> loginData) async {
    await _secureStorage.write(
      key: _keyPersistedSessionJson,
      value: jsonEncode(loginData),
    );
  }

  Future<void> clearPersistedSession() async {
    await _secureStorage.delete(key: _keyPersistedSessionJson);
  }

  Future<void> saveAppSnapshot(Map<String, dynamic> snapshot) async {
    await _secureStorage.write(
      key: _keyAppSnapshotJson,
      value: jsonEncode(snapshot),
    );
  }

  Future<Map<String, dynamic>?> loadAppSnapshot() async {
    final jsonStr = await _secureStorage.read(key: _keyAppSnapshotJson);
    if (jsonStr == null) return null;
    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    await clearAppSnapshot();
    return null;
  }

  Future<void> clearAppSnapshot() async {
    await _secureStorage.delete(key: _keyAppSnapshotJson);
  }

  /// Returns persisted login payload.
  /// Clears persisted session if payload is malformed.
  Future<Map<String, dynamic>?> loadPersistedSession() async {
    final jsonStr = await _secureStorage.read(key: _keyPersistedSessionJson);
    if (jsonStr == null) return null;

    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {}
    await clearPersistedSession();
    return null;
  }

  Future<void> _migrateLegacySensitiveData() async {
    final oldUsername = _prefs.getString(_keyUsername);
    final oldPasswordEncoded = _prefs.getString(_keyPassword);
    final oldSessionJson = _prefs.getString(_keyPersistedSessionJson);

    if (oldUsername != null &&
        (await _secureStorage.read(key: _keyUsername)) == null) {
      await _secureStorage.write(key: _keyUsername, value: oldUsername);
    }

    if (oldPasswordEncoded != null &&
        (await _secureStorage.read(key: _keyPassword)) == null) {
      try {
        final decoded = utf8.decode(base64Decode(oldPasswordEncoded));
        await _secureStorage.write(key: _keyPassword, value: decoded);
      } catch (_) {
        // Ignore malformed legacy value.
      }
    }

    if (oldSessionJson != null &&
        (await _secureStorage.read(key: _keyPersistedSessionJson)) == null) {
      await _secureStorage.write(key: _keyPersistedSessionJson, value: oldSessionJson);
    }

    await _prefs.remove(_keyUsername);
    await _prefs.remove(_keyPassword);
    await _prefs.remove(_keyPersistedSessionJson);
    await _prefs.remove('session_started_ms');
  }
}
