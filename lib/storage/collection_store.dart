import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

/// Shared "collection" state for the whole app:
/// - owned items (things you have)
/// - wishlist items (things you want)
///
/// We keep it generic, so Festival Songs can reuse it now,
/// and later the Fortnite Locker / Cosmetics can reuse the same store.
///
/// Data model in Hive:
/// box 'collection_state'
/// - key: 'owned:<category>' -> List<String>
/// - key: 'wish:<category>'  -> List<String>
class CollectionStore extends ChangeNotifier {
  static const String _boxName = 'collection_state';

  /// Category keys (keep them stable!)
  static const String categoryFestivalSong = 'festival_song';

  Box get _box => Hive.box(_boxName);

  Set<String> owned(String category) {
    final raw = _box.get('owned:$category');
    if (raw is List) {
      return raw.map((e) => e.toString()).toSet();
    }
    return <String>{};
  }

  Set<String> wishlist(String category) {
    final raw = _box.get('wish:$category');
    if (raw is List) {
      return raw.map((e) => e.toString()).toSet();
    }
    return <String>{};
  }

  bool isOwned(String category, String id) => owned(category).contains(id);
  bool isWished(String category, String id) => wishlist(category).contains(id);

  Future<void> setOwned(String category, String id, bool value) async {
    final set = owned(category);
    if (value) {
      set.add(id);
    } else {
      set.remove(id);
    }
    await _box.put('owned:$category', set.toList());
    notifyListeners();
  }

  Future<void> setWished(String category, String id, bool value) async {
    final set = wishlist(category);
    if (value) {
      set.add(id);
    } else {
      set.remove(id);
    }
    await _box.put('wish:$category', set.toList());
    notifyListeners();
  }

  Future<void> toggleOwned(String category, String id) async {
    await setOwned(category, id, !isOwned(category, id));
  }

  Future<void> toggleWished(String category, String id) async {
    await setWished(category, id, !isWished(category, id));
  }

  Future<void> clearCategory(String category) async {
    await _box.delete('owned:$category');
    await _box.delete('wish:$category');
    notifyListeners();
  }

  Future<void> clearAll() async {
    await _box.clear();
    notifyListeners();
  }
}
