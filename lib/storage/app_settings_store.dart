import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AppSettingsStore extends ChangeNotifier {
  static const String _boxName = 'settings';

  final Box _box;

  AppSettingsStore._(this._box);

  static Future<AppSettingsStore> create() async {
    final box = await Hive.openBox(_boxName);
    return AppSettingsStore._(box);
  }

  /// Wenn du die Box extern geleert hast, alles neu einlesen + UI updaten.
  void reloadFromBox() {
    notifyListeners();
  }
}
