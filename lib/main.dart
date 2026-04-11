import 'package:flutter/material.dart';
import 'app.dart';
import 'config/theme_provider.dart';

void main() {
  final themeProvider = ThemeProvider();
  runApp(
    ThemeProviderScope(
      provider: themeProvider,
      child: const DiaryApp(),
    ),
  );
}
