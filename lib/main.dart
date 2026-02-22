import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'screens/game_select_screen.dart';
import 'storage/app_settings_store.dart';
import 'storage/collection_store.dart';
import 'storage/update_store.dart';
import 'theme/orbit_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  await Hive.openBox('settings');
  await Hive.openBox('collection_state');

  final settings = await AppSettingsStore.create();
  settings.reloadFromBox();

  final updateStore = UpdateStore();
  final collection = CollectionStore();

  // ✅ Start-Theme setzen, damit Schrift/Look sofort stimmt
  OrbitTheme.currentDarkTheme = settings.darkTheme;

  runApp(
    OrbitApp(
      settings: settings,
      updateStore: updateStore,
      collection: collection,
    ),
  );
}

class OrbitApp extends StatelessWidget {
  final AppSettingsStore settings;
  final UpdateStore updateStore;
  final CollectionStore collection;

  const OrbitApp({
    super.key,
    required this.settings,
    required this.updateStore,
    required this.collection,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ Rebuild, sobald Settings geändert werden (Design Picker etc.)
    return AnimatedBuilder(
      animation: settings,
      builder: (context, _) {
        // ✅ Theme live aktualisieren
        OrbitTheme.currentDarkTheme = settings.darkTheme;

        return MaterialApp(
          title: 'Orbit',
          debugShowCheckedModeBanner: false,

          // ✅ Lesbare Schrift + konsistentes Design
          theme: OrbitTheme.light(),
          darkTheme: OrbitTheme.dark(),
          themeMode: ThemeMode.dark,

          home: GameSelectScreen(
            settings: settings,
            updateStore: updateStore,
            collection: collection,
          ),
        );
      },
    );
  }
}
