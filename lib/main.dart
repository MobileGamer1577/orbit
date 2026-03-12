import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'storage/app_settings_store.dart';
import 'storage/collection_store.dart';
import 'storage/update_store.dart';
import 'screens/game_select_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('task_state');
  await Hive.openBox('collection_state');

  final settings = await AppSettingsStore.create();
  final updateStore = UpdateStore();
  final collection = CollectionStore();

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
    return MaterialApp(
      title: 'Orbit',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      home: GameSelectScreen(
        settings: settings,
        updateStore: updateStore,
        collection: collection,
      ),
    );
  }
}
