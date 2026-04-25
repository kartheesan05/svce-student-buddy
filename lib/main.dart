import 'dart:async';
import 'package:flutter/material.dart';
import 'app.dart';
import 'config/theme_provider.dart';
import 'data/app_state.dart';
import 'data/prefs_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = PrefsService();
  await prefs.init();

  final themeProvider = ThemeProvider(prefs: prefs);
  final appState = AppState()..prefs = prefs;
  await appState.restoreSessionIfValid();

  runApp(
    ThemeProviderScope(
      provider: themeProvider,
      child: AppStateScope(
        state: appState,
        child: const DiaryApp(),
      ),
    ),
  );

  if (appState.isLoggedIn) {
    unawaited(appState.runStartupSyncInBackground());
  }
}
