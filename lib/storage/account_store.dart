import 'package:hive/hive.dart';

// ══════════════════════════════════════════════════════════════
//
//  🔐 ACCOUNT STORE
//  Datei: lib/storage/account_store.dart
//
//  Speichert Fortnite-OAuth-Daten lokal in Hive.
//  Alles bleibt auf dem Gerät — nichts wird an externe Server
//  übertragen (außer an Epic und api-fortnite.com für den Login).
//
//  Hive-Box: 'account_store'
//
//  Gespeicherte Felder:
//    fortnite_account_id     → Epic UUID (z.B. "a3f8...")
//    fortnite_display_name   → Anzeigename (z.B. "xoxoMobileGamerツ")
//    fortnite_token          → OAuth x-fortnite-token für API-Calls
//    fortnite_token_expiry   → ISO-8601 Ablaufzeit des Tokens
//
// ══════════════════════════════════════════════════════════════

class AccountStore {
  static const String _boxName = 'account_store';

  static const String _keyId     = 'fortnite_account_id';
  static const String _keyName   = 'fortnite_display_name';
  static const String _keyToken  = 'fortnite_token';
  static const String _keyExpiry = 'fortnite_token_expiry';

  static Box get _box => Hive.box(_boxName);

  // ── Getter ────────────────────────────────────────────────

  static String? get fortniteAccountId   => _box.get(_keyId)    as String?;
  static String? get fortniteDisplayName => _box.get(_keyName)  as String?;
  static String? get fortniteToken       => _box.get(_keyToken) as String?;

  static DateTime? get fortniteTokenExpiry {
    final raw = _box.get(_keyExpiry) as String?;
    if (raw == null) return null;
    try { return DateTime.parse(raw); } catch (_) { return null; }
  }

  /// true wenn Account-ID gespeichert ist
  static bool get isFortniteConnected {
    final id = fortniteAccountId;
    return id != null && id.isNotEmpty;
  }

  /// true wenn Token vorhanden UND noch mind. 5 Minuten gültig
  static bool get isFortniteTokenValid {
    final token  = fortniteToken;
    final expiry = fortniteTokenExpiry;
    if (token == null || token.isEmpty) return false;
    if (expiry == null) return true; // Kein Ablaufdatum → annehmen gültig
    return expiry.isAfter(DateTime.now().add(const Duration(minutes: 5)));
  }

  // ── Speichern ─────────────────────────────────────────────

  static Future<void> saveFortnite({
    required String accountId,
    required String displayName,
    required String token,
    DateTime? tokenExpiry,
  }) async {
    await _box.put(_keyId,    accountId.trim());
    await _box.put(_keyName,  displayName.trim());
    await _box.put(_keyToken, token.trim());
    if (tokenExpiry != null) {
      await _box.put(_keyExpiry, tokenExpiry.toIso8601String());
    }
  }

  /// Nur Token updaten (nach Refresh), Account-Daten bleiben
  static Future<void> updateToken({
    required String token,
    DateTime? tokenExpiry,
  }) async {
    await _box.put(_keyToken, token.trim());
    if (tokenExpiry != null) {
      await _box.put(_keyExpiry, tokenExpiry.toIso8601String());
    }
  }

  static Future<void> clearFortnite() async {
    await _box.deleteAll([_keyId, _keyName, _keyToken, _keyExpiry]);
  }
}
