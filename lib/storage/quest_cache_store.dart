import 'package:hive/hive.dart';
import '../models/api_quest.dart';

// ══════════════════════════════════════════════════════════════
//
//  💾 QUEST CACHE STORE
//  Datei: lib/storage/quest_cache_store.dart
//
//  Speichert Quest-Daten lokal in Hive für Offline-Support.
//
//  ┌─────────────────────────────────────────────────────────┐
//  │  WIE DER CACHE FUNKTIONIERT                             │
//  │                                                         │
//  │  1. App startet → Cache laden (sofort, offline)         │
//  │  2. Im Hintergrund → API anfragen                       │
//  │  3. API antwortet → Cache updaten + UI neu laden        │
//  │                                                         │
//  │  Ergebnis: Kein leerer Screen beim Start,               │
//  │  aber immer aktuelle Daten wenn online.                 │
//  └─────────────────────────────────────────────────────────┘
//
//  Hive Box: 'quest_cache'
//  Schlüssel-Format:
//    'data:{gameId}'        → serialisierte QuestApiResponse
//    'timestamp:{gameId}'   → letzter Update-Zeitpunkt (Unix ms)
//
// ══════════════════════════════════════════════════════════════

class QuestCacheStore {
  static const String _boxName = 'quest_cache';

  /// Cache-Gültigkeitsdauer: 1 Stunde
  /// ✏️  Anpassen falls du häufigere Updates willst
  static const Duration _cacheTtl = Duration(hours: 1);

  static Box get _box => Hive.box(_boxName);

  // ──────────────────────────────────────────────────────────
  //  Speichern
  // ──────────────────────────────────────────────────────────

  /// Speichert Quest-Daten für ein Spiel
  static Future<void> save(String gameId, QuestApiResponse data) async {
    await _box.put('data:$gameId', data.toJsonString());
    await _box.put('timestamp:$gameId', DateTime.now().millisecondsSinceEpoch);
  }

  // ──────────────────────────────────────────────────────────
  //  Laden
  // ──────────────────────────────────────────────────────────

  /// Lädt gecachte Quests oder null wenn kein Cache vorhanden
  static QuestApiResponse? load(String gameId) {
    final raw = _box.get('data:$gameId') as String?;
    if (raw == null) return null;
    try {
      return QuestApiResponse.fromJsonString(raw);
    } catch (_) {
      return null;
    }
  }

  // ──────────────────────────────────────────────────────────
  //  Cache-Status prüfen
  // ──────────────────────────────────────────────────────────

  /// Gibt true zurück wenn gecachte Daten vorhanden und noch frisch sind
  static bool isValid(String gameId) {
    final tsRaw = _box.get('timestamp:$gameId') as int?;
    if (tsRaw == null) return false;
    final saved  = DateTime.fromMillisecondsSinceEpoch(tsRaw);
    final age    = DateTime.now().difference(saved);
    return age < _cacheTtl;
  }

  /// Gibt true zurück wenn überhaupt Daten gecacht sind (auch veraltet)
  static bool hasData(String gameId) =>
      _box.get('data:$gameId') != null;

  /// Zeitpunkt des letzten Updates (oder null)
  static DateTime? lastUpdated(String gameId) {
    final tsRaw = _box.get('timestamp:$gameId') as int?;
    if (tsRaw == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(tsRaw);
  }

  // ──────────────────────────────────────────────────────────
  //  Cache leeren
  // ──────────────────────────────────────────────────────────

  /// Löscht den Cache für ein Spiel → nächster Start lädt von API
  static Future<void> clear(String gameId) async {
    await _box.delete('data:$gameId');
    await _box.delete('timestamp:$gameId');
  }

  /// Löscht ALLE gecachten Quests (alle Spiele)
  static Future<void> clearAll() async {
    final keys = _box.keys
        .where((k) => k.toString().startsWith('data:') ||
                      k.toString().startsWith('timestamp:'))
        .toList();
    await _box.deleteAll(keys);
  }
}
