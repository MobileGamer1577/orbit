import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AppSettingsStore extends ChangeNotifier {
  static const String _boxName = 'settings';
  static const String _keyLanguage = 'language';

  final Box _box;

  AppSettingsStore._(this._box);

  static Future<AppSettingsStore> create() async {
    final box = await Hive.openBox(_boxName);
    return AppSettingsStore._(box);
  }

  // ── Sprache ────────────────────────────────────────────
  /// Unterstützte Sprachen: 'de' (Standard) und 'en'
  String get language => (_box.get(_keyLanguage) as String?) ?? 'de';

  Locale get locale => Locale(language);

  Future<void> setLanguage(String lang) async {
    await _box.put(_keyLanguage, lang);
    notifyListeners();
  }

  // ── Allgemein ──────────────────────────────────────────
  /// Wenn du die Box extern geleert hast, alles neu einlesen + UI updaten.
  void reloadFromBox() {
    notifyListeners();
  }
}
