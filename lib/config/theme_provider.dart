import 'package:flutter/material.dart';

enum ThemeSource { dynamic, defaultSeed }

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  ThemeSource _themeSource = ThemeSource.dynamic;

  ThemeMode get themeMode => _themeMode;
  ThemeSource get themeSource => _themeSource;

  bool get useDynamicColor => _themeSource == ThemeSource.dynamic;

  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
  }

  void setThemeSource(ThemeSource source) {
    if (_themeSource == source) return;
    _themeSource = source;
    notifyListeners();
  }

  static ThemeProvider of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<ThemeProviderScope>()!
        .provider;
  }
}

class ThemeProviderScope extends InheritedWidget {
  final ThemeProvider provider;

  const ThemeProviderScope({
    super.key,
    required this.provider,
    required super.child,
  });

  @override
  bool updateShouldNotify(ThemeProviderScope oldWidget) =>
      provider != oldWidget.provider;
}
