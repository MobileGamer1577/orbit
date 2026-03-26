import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'l10n/app_localizations.dart';
import 'storage/app_settings_store.dart';
import 'storage/collection_store.dart';
import 'storage/update_store.dart';
import 'theme/orbit_theme.dart';
import 'screens/game_select_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('task_state');
  await Hive.openBox('collection_state');
  await Hive.openBox('cosmetic_meta');   // ← NEU: Cosmetic-Metadaten

  final settings = await AppSettingsStore.create();
  final updateStore = UpdateStore();
  final collection = CollectionStore();

  runApp(OrbitApp(
    settings: settings,
    updateStore: updateStore,
    collection: collection,
  ));
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
  @override
  void initState() {
    super.initState();
    widget.settings.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    widget.settings.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Orbit',
      debugShowCheckedModeBanner: false,
      color: const Color(0xFF07020F),
      theme: OrbitTheme.light(),
      darkTheme: OrbitTheme.dark(),
      themeMode: ThemeMode.dark,

      locale: widget.settings.locale,
      supportedLocales: const [
        Locale('de'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      home: GameSelectScreen(
        settings: widget.settings,
        updateStore: widget.updateStore,
        collection: widget.collection,
      ),
    );
  }
}
