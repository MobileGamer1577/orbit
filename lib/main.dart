import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'screens/game_select_screen.dart';
import 'storage/app_settings_store.dart';
import 'storage/collection_store.dart';
import 'storage/update_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  // Settings / Update state
  await Hive.openBox('app_settings');
  await Hive.openBox('update_state');

  // Shared collection state (Owned/Wishlist)
  await Hive.openBox('collection_state');

  final settings = AppSettingsStore();
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
