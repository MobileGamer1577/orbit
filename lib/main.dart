import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'screens/game_select_screen.dart';
import 'theme/orbit_theme.dart';
import 'storage/app_settings_store.dart';
import 'storage/update_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await Hive.openBox('task_state');
  await Hive.openBox('settings');

  final settings = await AppSettingsStore.create();
  settings.reloadFromBox();

  final updateStore = UpdateStore();
  updateStore.check(); // Start-Check

  runApp(OrbitApp(settings: settings, updateStore: updateStore));
}

class OrbitApp extends StatelessWidget {
  final AppSettingsStore settings;
  final UpdateStore updateStore;

  const OrbitApp({
    super.key,
    required this.settings,
    required this.updateStore,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ Nur settings triggert App-Rebuild (Theme/Design)
    return AnimatedBuilder(
      animation: settings,
      builder: (_, __) {
        return MaterialApp(
          title: 'Orbit',
          debugShowCheckedModeBanner: false,
          theme: OrbitTheme.light(),
          darkTheme: OrbitTheme.dark(),
          themeMode: ThemeMode.dark,
          home: GameSelectScreen(settings: settings, updateStore: updateStore),
        );
      },
    );
  }
}