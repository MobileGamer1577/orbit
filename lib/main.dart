import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/game_select_screen.dart';
import 'storage/app_settings_store.dart';
import 'storage/collection_store.dart';
import 'storage/update_store.dart';
import 'theme/orbit_theme.dart';
import 'core/constants.dart';
import 'core/supabase_client.dart';
import 'features/auth/logout_button.dart';
import 'features/cod_integration/cod_settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // Hive Boxen öffnen
  await Hive.openBox('task_state');
  await Hive.openBox('collection_state');

  // Settings laden
  final settings = await AppSettingsStore.create();
  settings.reloadFromBox();

  final updateStore = UpdateStore();
  final collection = CollectionStore();

  // Start-Theme setzen
  OrbitTheme.currentDarkTheme = settings.darkTheme;

  // Supabase initialisieren
  await SupabaseClientManager.init();

  runApp(
    OrbitApp(
      settings: settings,
      updateStore: updateStore,
      collection: collection,
    ),
  );
}

class OrbitApp extends StatefulWidget {
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
  State<OrbitApp> createState() => _OrbitAppState();
}

class _OrbitAppState extends State<OrbitApp> {
  bool _checkingSession = true;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final session = SupabaseClientManager.client.auth.currentSession;
    if (session == null) {
      // User nicht eingeloggt → Discord OAuth starten
      await SupabaseClientManager.client.auth.signInWithOAuth(
        OAuthProvider.discord,
      );
    }
    setState(() {
      _checkingSession = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Theme live aktualisieren
    OrbitTheme.currentDarkTheme = widget.settings.darkTheme;

    if (_checkingSession) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    // Haupt-App mit GameSelectScreen und zusätzlichen Widgets
    return MaterialApp(
      title: 'Orbit',
      debugShowCheckedModeBanner: false,
      theme: OrbitTheme.light(),
      darkTheme: OrbitTheme.dark(),
      themeMode: ThemeMode.dark,
      home: Scaffold(
        body: GameSelectScreen(
          settings: widget.settings,
          updateStore: widget.updateStore,
          collection: widget.collection,
        ),
        // Optional: Logout & CoD Settings Overlay oder dauerhaft unten
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [LogoutButton(), CodSettingsWidget()],
        ),
      ),
    );
  }
}
