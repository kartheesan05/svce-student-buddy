import 'package:flutter/material.dart';
import 'app.dart';
import 'config/theme_provider.dart';
import 'data/app_state.dart';

void main() {
  final themeProvider = ThemeProvider();
  final appState = AppState();
  runApp(
    ThemeProviderScope(
      provider: themeProvider,
      child: AppStateScope(
        state: appState,
        child: const DiaryApp(),
      ),
    ),
  );
}
