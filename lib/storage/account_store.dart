import 'package:hive/hive.dart';

// ══════════════════════════════════════════════════════════════
//
//  🔐 ACCOUNT STORE
//  Datei: lib/storage/account_store.dart
//
//  Speichert Fortnite-OAuth-Daten lokal in Hive.
//
//  ── GESPEICHERTE FELDER ───────────────────────────────────
//
//  fortnite_account_id   → Epic UUID
//  fortnite_display_name → Anzeigename
//  fortnite_token        → x-fortnite-token für API-Calls
//  fortnite_token_expiry → Token-Ablaufzeit (ISO-8601)
//  fortnite_device_id    → Device-ID für stillen Re-Login
//  fortnite_device_secret→ Secret für stillen Re-Login
//
//  Mit deviceId + deviceSecret kann die App den Token im
//  Hintergrund erneuern — ohne Browser, ohne Nutzer-Aktion.
//
//  Hive-Box: 'account_store'
//
// ══════════════════════════════════════════════════════════════

class AccountStore {
  static const String _boxName = 'account_store';

  static const String _keyId            = 'fortnite_account_id';
  static const String _keyName          = 'fortnite_display_name';
  static const String _keyToken         = 'fortnite_token';
  static const String _keyExpiry        = 'fortnite_token_expiry';
  static const String _keyDeviceId      = 'fortnite_device_id';
  static const String _keyDeviceSecret  = 'fortnite_device_secret';

  static Box get _box => Hive.box(_boxName);

  // ── Getter ────────────────────────────────────────────────

  static String? get fortniteAccountId    => _box.get(_keyId)           as String?;
  static String? get fortniteDisplayName  => _box.get(_keyName)         as String?;
  static String? get fortniteToken        => _box.get(_keyToken)        as String?;
  static String? get fortniteDeviceId     => _box.get(_keyDeviceId)     as String?;
  static String? get fortniteDeviceSecret => _box.get(_keyDeviceSecret) as String?;

  static DateTime? get fortniteTokenExpiry {
    final raw = _box.get(_keyExpiry) as String?;
    if (raw == null) return null;
    try { return DateTime.parse(raw); } catch (_) { return null; }
  }

  static bool get isFortniteConnected {
    final id = fortniteAccountId;
    return id != null && id.isNotEmpty;
  }

  /// true wenn Token vorhanden UND noch mind. 5 Minuten gültig
  /// true wenn ein Token vorhanden ist.
  /// Wir prüfen Ablauf NICHT vorab — stattdessen wird bei HTTP 401
  /// automatisch ein stiller Re-Login gemacht (refresh-device).
  static bool get isFortniteTokenValid {
    final token = fortniteToken;
    return token != null && token.isNotEmpty;
  }

  /// true wenn stiller Re-Login möglich (deviceId + secret vorhanden)
  static bool get canRefreshSilently {
    final id     = fortniteAccountId;
    final devId  = fortniteDeviceId;
    final secret = fortniteDeviceSecret;
    return id != null && devId != null && secret != null &&
           id.isNotEmpty && devId.isNotEmpty && secret.isNotEmpty;
  }

  // ── Speichern ─────────────────────────────────────────────

  static Future<void> saveFortnite({
    required String accountId,
    required String displayName,
    required String token,
    DateTime? tokenExpiry,
    String? deviceId,
    String? deviceSecret,
  }) async {
    await _box.put(_keyId,   accountId.trim());
    await _box.put(_keyName, displayName.trim());
    await _box.put(_keyToken, token.trim());
    if (tokenExpiry != null) {
      await _box.put(_keyExpiry, tokenExpiry.toIso8601String());
    }
    if (deviceId != null && deviceId.isNotEmpty) {
      await _box.put(_keyDeviceId, deviceId.trim());
    }
    if (deviceSecret != null && deviceSecret.isNotEmpty) {
      await _box.put(_keyDeviceSecret, deviceSecret.trim());
    }
  }

  /// Nur Token updaten (nach Refresh)
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
    await _box.deleteAll([
      _keyId, _keyName, _keyToken, _keyExpiry,
      _keyDeviceId, _keyDeviceSecret,
    ]);
  }
}