import 'package:flutter/material.dart';
import '../data/prefs_service.dart';

enum ThemeSource { dynamic, defaultSeed }

class ThemeProvider extends ChangeNotifier {
  final PrefsService _prefs;

  late ThemeMode _themeMode;
  late ThemeSource _themeSource;

  ThemeProvider({required PrefsService prefs}) : _prefs = prefs {
    _themeMode = prefs.themeMode;
    _themeSource = prefs.themeSource;
  }

  ThemeMode get themeMode => _themeMode;
  ThemeSource get themeSource => _themeSource;

  bool get useDynamicColor => _themeSource == ThemeSource.dynamic;

  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    _prefs.setThemeMode(mode);
    notifyListeners();
  }

  void setThemeSource(ThemeSource source) {
    if (_themeSource == source) return;
    _themeSource = source;
    _prefs.setThemeSource(source);
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
