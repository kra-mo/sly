import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

final lightThemeData = ThemeData(
  useMaterial3: true,
  fontFamily: 'Geist',
  splashColor: Colors.transparent,
  highlightColor: Colors.transparent,
  primaryColorDark: Colors.grey.shade400,
  primaryColorLight: Colors.white,
  disabledColor: Colors.grey.shade400,
  focusColor: Colors.black12,
  colorScheme: ColorScheme(
    brightness: Brightness.light,
    primary: Colors.grey.shade800,
    onPrimary: Colors.white,
    secondary: Colors.grey.shade300,
    onSecondary: Colors.grey.shade800,
    error: Colors.red.shade200,
    onError: Colors.black,
    surface: Colors.grey.shade200,
    onSurface: Colors.grey.shade800,
  ),
);

final darkThemeData = ThemeData(
  useMaterial3: true,
  fontFamily: 'Geist',
  splashColor: Colors.transparent,
  highlightColor: Colors.transparent,
  primaryColorDark: Colors.black,
  primaryColorLight: Colors.grey.shade800,
  disabledColor: Colors.grey.shade700,
  hintColor: Colors.grey.shade500,
  focusColor: Colors.white12,
  hoverColor: Colors.white10,
  colorScheme: ColorScheme(
    brightness: Brightness.dark,
    primary: Colors.white,
    onPrimary: Colors.grey.shade900,
    secondary: Colors.grey.shade800,
    onSecondary: Colors.white,
    error: Colors.red.shade900,
    onError: Colors.white,
    surface: Colors.grey.shade900,
    onSurface: Colors.white,
  ),
);

class LightTheme extends StatelessWidget {
  const LightTheme({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CupertinoTheme(
      data: const CupertinoThemeData(brightness: Brightness.light),
      child: Theme(data: lightThemeData, child: child),
    );
  }
}

class DarkTheme extends StatelessWidget {
  const DarkTheme({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CupertinoTheme(
      data: const CupertinoThemeData(brightness: Brightness.dark),
      child: Theme(data: darkThemeData, child: child),
    );
  }
}
