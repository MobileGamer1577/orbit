import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'screens/game_select_screen.dart';
import 'storage/app_settings_store.dart';
import 'theme/orbit_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await Hive.openBox('task_state');
  await Hive.openBox('settings');

  final settings = await AppSettingsStore.create();

  // Beim App-Start Theme aus Settings übernehmen
  OrbitTheme.currentDarkTheme = settings.darkTheme;

  runApp(OrbitApp(settings: settings));
}

class OrbitApp extends StatelessWidget {
  final AppSettingsStore settings;

  const OrbitApp({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: settings,
      builder: (_, __) {
        // falls sich Theme ändert: immer aktuell setzen
        OrbitTheme.currentDarkTheme = settings.darkTheme;

        return MaterialApp(
          title: 'Orbit',
          debugShowCheckedModeBanner: false,

          // Light kannst du drin lassen, aber genutzt wird nur dark
          theme: OrbitTheme.light(),
          darkTheme: OrbitTheme.dark(),

          // ✅ Immer Dark (keine System / Hell Auswahl mehr)
          themeMode: ThemeMode.dark,

          home: GameSelectScreen(settings: settings),
        );
      },
    );
  }
}