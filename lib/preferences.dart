import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '/widgets/dialog.dart';
import '/widgets/toggle_buttons.dart';

final Future<SharedPreferences> prefs = SharedPreferences.getInstance();
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);

/// Initializes preferences.
///
/// Be sure to call this once before using anything from this module.
Future<void> initPreferences() async {
  final style = (await prefs).getInt('theme');
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
    SlyToggleButtons(
      compact: true,
      defaultItem: themeNotifier.value == ThemeMode.dark
          ? 0
          : themeNotifier.value == ThemeMode.system
              ? 1
              : 2,
      onSelected: (index) async {
        (await prefs).setInt('theme', index);

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
    const SizedBox(height: 8),
    const SlyCancelButton(label: 'Done', suggested: false),
  ]);
}
