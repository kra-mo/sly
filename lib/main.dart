import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import 'package:window_manager/window_manager.dart';

import '/platform.dart';
import '/theme.dart';
import '/preferences.dart';
import '/widgets/unique/home.dart';

void main() async {
  runApp(const SlyApp());

  await initPreferences();

  if (isDesktop) {
    await windowManager.ensureInitialized();
  }
  if (isWindows) {
    windowManager.setMinimumSize(const Size(360, 294));
  }
}

class SlyApp extends StatelessWidget {
  const SlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, style, child) {
        switch (style) {
          case ThemeMode.dark:
            SystemChrome.setSystemUIOverlayStyle(darkSystemUiOverlayStyle);
          case ThemeMode.light:
            SystemChrome.setSystemUIOverlayStyle(lightSystemUiOverlayStyle);
          case ThemeMode.system:
            SystemChrome.setSystemUIOverlayStyle(
              MediaQuery.of(context).platformBrightness == Brightness.light
                  ? lightSystemUiOverlayStyle
                  : darkSystemUiOverlayStyle,
            );
        }

        return MaterialApp(
          title: 'Sly',
          home: const SlyHomePage(title: 'Home'),
          debugShowCheckedModeBanner: false,
          themeMode: style,
          theme: lightThemeData,
          darkTheme: darkThemeData,
        );
      },
    );
  }
}
