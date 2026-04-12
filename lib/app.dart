import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'config/theme.dart';
import 'config/theme_provider.dart';
import 'data/app_state.dart';
import 'screens/login/login_screen.dart';
import 'screens/navigation_shell.dart';

/// Refreshes server-backed data when the app returns to the foreground after
/// having been backgrounded (avoids an extra fetch on cold start).
class AppForegroundRefresh extends StatefulWidget {
  const AppForegroundRefresh({super.key, required this.child});

  final Widget child;

  @override
  State<AppForegroundRefresh> createState() => _AppForegroundRefreshState();
}

class _AppForegroundRefreshState extends State<AppForegroundRefresh>
    with WidgetsBindingObserver {
  AppLifecycleState? _previous;
  bool _wasInBackground = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final previous = _previous;
    _previous = state;

    if (previous == AppLifecycleState.resumed &&
        (state == AppLifecycleState.paused ||
            state == AppLifecycleState.inactive)) {
      _wasInBackground = true;
    }
    if (state == AppLifecycleState.resumed && _wasInBackground && mounted) {
      _wasInBackground = false;
      final appState = AppStateScope.of(context);
      if (appState.isLoggedIn) {
        appState.refreshAllData();
      }
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class DiaryApp extends StatelessWidget {
  const DiaryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AppForegroundRefresh(
      child: DynamicColorBuilder(
        builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
          return ListenableBuilder(
            listenable: ThemeProvider.of(context),
            builder: (context, _) {
              final provider = ThemeProvider.of(context);
              final useDynamic = provider.useDynamicColor;

              return MaterialApp(
                title: 'Diary',
                debugShowCheckedModeBanner: false,
                theme: AppTheme.light(useDynamic ? lightDynamic : null),
                darkTheme: AppTheme.dark(useDynamic ? darkDynamic : null),
                themeMode: provider.themeMode,
                builder: (context, child) {
                  final brightness = Theme.of(context).brightness;
                  final colorScheme = Theme.of(context).colorScheme;
                  return AnnotatedRegion<SystemUiOverlayStyle>(
                    value: SystemUiOverlayStyle(
                      systemNavigationBarColor: colorScheme.surface,
                      systemNavigationBarIconBrightness: brightness == Brightness.dark
                          ? Brightness.light
                          : Brightness.dark,
                    ),
                    child: child!,
                  );
                },
                home: ListenableBuilder(
                  listenable: AppStateScope.of(context),
                  builder: (context, _) {
                    final appState = AppStateScope.of(context);
                    if (appState.isLoggedIn) {
                      return const NavigationShell();
                    }
                    return const LoginScreen();
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
