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
}
