import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/supabase_client.dart';
import 'core/constants.dart';
import 'features/auth/login_page.dart';
import 'storage/app_settings_store.dart';
import 'storage/collection_store.dart';
import 'storage/update_store.dart';
import 'theme/orbit_theme.dart';
import 'screens/game_select_screen.dart';
import 'features/auth/auth_repository.dart';
import 'features/auth/logout_button.dart';
import 'features/cod_integration/cod_settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('task_state');
  await Hive.openBox('collection_state');

  final settings = await AppSettingsStore.create();
  settings.reloadFromBox();
  final updateStore = UpdateStore();
  final collection = CollectionStore();

  OrbitTheme.currentDarkTheme = settings.darkTheme;

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
    final session = AuthRepository.currentSession();
    if (session == null) {
      // Kein User eingeloggt → LoginPage anzeigen
      setState(() => _checkingSession = false);
      return;
    }
    setState(() => _checkingSession = false);
  }

  @override
  Widget build(BuildContext context) {
    OrbitTheme.currentDarkTheme = widget.settings.darkTheme;

    if (_checkingSession) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    // Wenn User nicht eingeloggt → LoginPage
    final session = AuthRepository.currentSession();
    if (session == null) {
      return const MaterialApp(home: LoginPage());
    }

    // User eingeloggt → normale App
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
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [LogoutButton(), CodSettingsWidget()],
        ),
      ),
    );
  }
}
