import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../theme/orbit_theme.dart';

class AppSettingsStore extends ChangeNotifier {
  static const String _boxName = 'settings';

  static const String _kDarkThemeName = 'dark_theme_name'; // enum name: purple, blue, ...

  final Box _box;

  AppSettingsStore._(this._box);

  static Future<AppSettingsStore> create() async {
    final box = await Hive.openBox(_boxName);
    return AppSettingsStore._(box);
  }

  /// Aktuell gewähltes Dark Theme (Enum)
  OrbitDarkTheme get darkTheme {
    final raw = (_box.get(_kDarkThemeName) as String?)?.trim();
    if (raw == null || raw.isEmpty) return OrbitDarkTheme.purple;
    return OrbitTheme.fromName(raw);
  }

  /// Anzeige-Name fürs UI
  String get darkThemeDisplayName => OrbitTheme.displayName(darkTheme);

  /// Setzt Dark Theme (speichert Enum-Name)
  Future<void> setDarkTheme(OrbitDarkTheme theme) async {
    await _box.put(_kDarkThemeName, theme.name);

    // Wichtig: Globales Theme updaten, damit Gradient/Seed sofort stimmen
    OrbitTheme.currentDarkTheme = theme;

    notifyListeners();
  }

  /// Wenn du die Box extern geleert hast (z.B. Daten löschen),
  /// kannst du damit alles neu einlesen + UI updaten.
  void reloadFromBox() {
    OrbitTheme.currentDarkTheme = darkTheme;
    notifyListeners();
  }
}