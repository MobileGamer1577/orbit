import 'package:hive/hive.dart';

// ══════════════════════════════════════════════════════════════
//
//  🔐 ACCOUNT STORE
//  Datei: lib/storage/account_store.dart
//
//  Speichert Fortnite-Account-Daten lokal in Hive.
//  Daten bleiben offline verfügbar und werden NICHT mit
//  irgendwelchen Servern geteilt — alles bleibt auf dem Gerät.
//
//  Hive-Box: 'account_store'
//
//  Gespeicherte Daten:
//    'fortnite_account_id'    → Epic Games Account-ID (UUID)
//    'fortnite_display_name'  → Angezeigter Name im Spiel
//
//  Verwendung:
//    import '../storage/account_store.dart';
//
//    final id = AccountStore.fortniteAccountId;
//    await AccountStore.saveFortnite(id: '...', displayName: '...');
//    await AccountStore.clearFortnite();
//
// ══════════════════════════════════════════════════════════════

class AccountStore {
  static const String _boxName = 'account_store';

  static const String _keyFortniteId   = 'fortnite_account_id';
  static const String _keyFortniteName = 'fortnite_display_name';

  static Box get _box => Hive.box(_boxName);

  // ── Getter ────────────────────────────────────────────────

  /// Epic Games Account-ID (UUID), oder null wenn nicht verbunden
  static String? get fortniteAccountId =>
      _box.get(_keyFortniteId) as String?;

  /// Angezeigter Fortnite-Name, oder null wenn nicht verbunden
  static String? get fortniteDisplayName =>
      _box.get(_keyFortniteName) as String?;

  /// true wenn ein Fortnite-Account verbunden ist
  static bool get isFortniteConnected {
    final id = fortniteAccountId;
    return id != null && id.isNotEmpty;
  }

  // ── Speichern ─────────────────────────────────────────────

  /// Account-Daten speichern (nach erfolgreicher Verbindung)
  static Future<void> saveFortnite({
    required String accountId,
    required String displayName,
  }) async {
    await _box.put(_keyFortniteId,   accountId.trim());
    await _box.put(_keyFortniteName, displayName.trim());
  }

  /// Fortnite-Verbindung trennen
  static Future<void> clearFortnite() async {
    await _box.delete(_keyFortniteId);
    await _box.delete(_keyFortniteName);
  }

  // ── Zukunft: Weitere Spiele ───────────────────────────────
  //
  // Wenn BO7-Account nötig wird:
  //   static const String _keyBo7Id   = 'bo7_account_id';
  //   static const String _keyBo7Name = 'bo7_display_name';
  //   static String? get bo7AccountId => ...
  //   static Future<void> saveBo7(...) async { ... }
}
