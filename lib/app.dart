import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
                  final toastMessage = appState.consumeToastMessage();
                  if (toastMessage != null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!context.mounted) return;
                      final messenger = ScaffoldMessenger.maybeOf(context);
                      messenger?.showSnackBar(
                        SnackBar(content: Text(toastMessage)),
                      );
                    });
                  }
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
