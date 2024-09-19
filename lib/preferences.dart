import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'dialog.dart';
import 'button.dart';
import 'toggle_buttons.dart';

SharedPreferences? _prefs;
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);

/// Initializes preferences.
///
/// Make sure to call this once before using anything from this module.
Future<void> initPreferences() async {
  _prefs = await SharedPreferences.getInstance();
  if (_prefs == null) return;

  final style = _prefs!.getInt('theme');
  if (style == null) return;

  switch (style) {
    case 0:
      themeNotifier.value = ThemeMode.dark;
    case 1:
      themeNotifier.value = ThemeMode.system;
    case 2:
      themeNotifier.value = ThemeMode.light;
  }
}

void showSlyPreferencesDialog(BuildContext context) {
  showSlyDialog(context, 'Appearance', <Widget>[
    Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: SlyToggleButtons(
        compact: true,
        defaultItem: themeNotifier.value == ThemeMode.dark
            ? 0
            : themeNotifier.value == ThemeMode.system
                ? 1
                : 2,
        onSelected: (index) {
          _prefs?.setInt('theme', index);

          switch (index) {
            case 0:
              themeNotifier.value = ThemeMode.dark;
            case 1:
              themeNotifier.value = ThemeMode.system;
            case 2:
              themeNotifier.value = ThemeMode.light;
          }
        },
        children: const <Widget>[
          Text('Dark'),
          Text('System'),
          Text('Light'),
        ],
      ),
    ),
    SlyButton(
      onPressed: () {
        Navigator.pop(context);
      },
      child: const Text('Done'),
    ),
  ]);
}
