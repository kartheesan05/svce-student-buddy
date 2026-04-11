import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'config/theme.dart';
import 'screens/navigation_shell.dart';

class DiaryApp extends StatelessWidget {
  const DiaryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        return MaterialApp(
          title: 'Diary',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(lightDynamic),
          darkTheme: AppTheme.dark(darkDynamic),
          themeMode: ThemeMode.system,
          home: const NavigationShell(),
        );
      },
    );
  }
}
