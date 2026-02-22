import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'screens/game_select_screen.dart';
import 'storage/app_settings_store.dart';
import 'storage/collection_store.dart';
import 'storage/update_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // Boxen öffnen (müssen zu deinen Stores passen)
  await Hive.openBox('settings');
  await Hive.openBox('collection_state');

  final settings = await AppSettingsStore.create();
  settings.reloadFromBox();

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
      home: GameSelectScreen(
        settings: settings,
        updateStore: updateStore,
        collection: collection,
      ),
    );
  }
}
