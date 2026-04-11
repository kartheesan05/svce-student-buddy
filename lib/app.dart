import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'config/theme.dart';
import 'config/theme_provider.dart';
import 'data/app_state.dart';
import 'screens/login/login_screen.dart';
import 'screens/navigation_shell.dart';

class DiaryApp extends StatelessWidget {
  const DiaryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
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
    );
  }
}
