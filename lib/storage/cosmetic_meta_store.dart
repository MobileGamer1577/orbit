import 'dart:convert';
import 'package:hive/hive.dart';
import '../models/cosmetic_item.dart';

/// Hive-Store für Cosmetic-Metadaten.
/// Speichert Name, Bild-URL usw. wenn ein Cosmetic zum Spind/Wunschliste hinzugefügt wird.
/// So können Spind & Wunschliste offline angezeigt werden.
class CosmeticMetaStore {
  static const String boxName = 'cosmetic_meta';

  static Box get _box => Hive.box(boxName);

  /// Speichert oder überschreibt Metadaten eines Cosmetics.
  static Future<void> save(CosmeticItem item) async {
    await _box.put(item.id.toLowerCase(), item.toJsonString());
  }

  /// Lädt ein Cosmetic anhand seiner ID. Gibt null zurück wenn nicht vorhanden.
  static CosmeticItem? get(String id) {
    final raw = _box.get(id.toLowerCase());
    if (raw == null) return null;
    try {
      return CosmeticItem.fromJson(
        jsonDecode(raw as String) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  /// Lädt mehrere Cosmetics anhand ihrer IDs. Unbekannte IDs werden ignoriert.
  static List<CosmeticItem> getMultiple(Iterable<String> ids) {
    return ids.map(get).whereType<CosmeticItem>().toList();
  }
}
