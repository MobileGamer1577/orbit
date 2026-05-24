import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AppSettingsStore extends ChangeNotifier {
  static const String _boxName     = 'settings';
  static const String _keyLanguage = 'language';

  // ── Animations-Keys ────────────────────────────────────────
  static const String _keyAnimAll       = 'anim_all';
  static const String _keyAnimRainbow   = 'anim_rainbow';
  static const String _keyAnimJurassic  = 'anim_jurassic';
  static const String _keyAnimCountdown = 'anim_countdown';
  static const String _keyAnimShop      = 'anim_shop';

  final Box _box;

  AppSettingsStore._(this._box);

  // ── Singleton ──────────────────────────────────────────────
  //
  // Ermöglicht Zugriff auf die Settings von überall in der App,
  // ohne sie durch jeden Navigator-Stack manuell durchzureichen.
  //
  // Verwendung:  AppSettingsStore.instance.animJurassic
  //
  static AppSettingsStore? _instance;

  /// Gibt die globale Instanz zurück.
  /// Wirft einen Fehler wenn create() noch nicht aufgerufen wurde.
  static AppSettingsStore get instance {
    assert(_instance != null,
        'AppSettingsStore.create() muss vor instance aufgerufen werden.');
    return _instance!;
  }

  static Future<AppSettingsStore> create() async {
    final box  = await Hive.openBox(_boxName);
    _instance  = AppSettingsStore._(box);
    return _instance!;
  }

  // ── Sprache ────────────────────────────────────────────────
  String get language => (_box.get(_keyLanguage) as String?) ?? 'de';
  Locale get locale   => Locale(language);

  Future<void> setLanguage(String lang) async {
    await _box.put(_keyLanguage, lang);
    notifyListeners();
  }

  // ── Animationen ────────────────────────────────────────────
  //
  //  animAll  = Master-Schalter.
  //  Ist er false → alle Einzelwerte gelten als false.
  //  Ist er true  → die Einzelschalter entscheiden.

  bool get animAll => (_box.get(_keyAnimAll, defaultValue: true) as bool);

  // Effektive Werte (mit Master-Override)
  bool get animRainbow   => animAll && (_box.get(_keyAnimRainbow,   defaultValue: true) as bool);
  bool get animJurassic  => animAll && (_box.get(_keyAnimJurassic,  defaultValue: true) as bool);
  bool get animCountdown => animAll && (_box.get(_keyAnimCountdown, defaultValue: true) as bool);
  bool get animShop      => animAll && (_box.get(_keyAnimShop,      defaultValue: true) as bool);

  // Rohe Werte (für UI-Toggle-Darstellung, ohne Master-Override)
  bool get animRainbowRaw   => (_box.get(_keyAnimRainbow,   defaultValue: true) as bool);
  bool get animJurassicRaw  => (_box.get(_keyAnimJurassic,  defaultValue: true) as bool);
  bool get animCountdownRaw => (_box.get(_keyAnimCountdown, defaultValue: true) as bool);
  bool get animShopRaw      => (_box.get(_keyAnimShop,      defaultValue: true) as bool);

  Future<void> setAnimAll(bool v) async {
    await _box.put(_keyAnimAll, v);
    notifyListeners();
  }

  Future<void> setAnimRainbow(bool v) async {
    await _box.put(_keyAnimRainbow, v);
    notifyListeners();
  }

  Future<void> setAnimJurassic(bool v) async {
    await _box.put(_keyAnimJurassic, v);
    notifyListeners();
  }

  Future<void> setAnimCountdown(bool v) async {
    await _box.put(_keyAnimCountdown, v);
    notifyListeners();
  }

  Future<void> setAnimShop(bool v) async {
    await _box.put(_keyAnimShop, v);
    notifyListeners();
  }

  // ── Allgemein ──────────────────────────────────────────────
  void reloadFromBox() => notifyListeners();
}
