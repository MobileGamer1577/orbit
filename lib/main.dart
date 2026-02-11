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
  settings.reloadFromBox(); // sorgt dafür, dass OrbitTheme.currentDarkTheme gesetzt ist

  final updateStore = UpdateStore();
  // ✅ Start-Check (läuft einmal beim Start)
  // Wenn kein Internet/WLAN: error wird gesetzt, aber App läuft normal weiter.
  updateStore.check();

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
    return AnimatedBuilder(
      animation: Listenable.merge([settings, updateStore]),
      builder: (_, __) {
        return MaterialApp(
          title: 'Orbit',
          debugShowCheckedModeBanner: false,
          theme: OrbitTheme.light(),
          darkTheme: OrbitTheme.dark(),
          themeMode: ThemeMode.dark, // App bleibt dark
          home: GameSelectScreen(settings: settings, updateStore: updateStore),
        );
      },
    );
  }
}