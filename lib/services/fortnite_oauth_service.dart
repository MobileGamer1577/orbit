import 'dart:convert';
import 'dart:developer' as dev;
import 'package:http/http.dart' as http;
import '../config/api_keys.dart';
import '../storage/account_store.dart';

// ══════════════════════════════════════════════════════════════
//
//  🔑 FORTNITE OAUTH SERVICE
//  Datei: lib/services/fortnite_oauth_service.dart
//
//  Flow (kein Pro-Plan nötig):
//    1. Epic OAuth URL direkt bauen (kein API-Call!)
//       → https://www.epicgames.com/id/authorize?...
//    2. WebView → User loggt sich ein
//       → Redirect auf localhost/callback?code=...
//       → WebView fängt Code ab
//    3. POST /api/v1/oauth/link { "code": "...", "redirect_uri": "..." }
//       → Fortnite Token + DeviceAuth
//       Fallback: POST /api/v1/oauth/exchange-code
//
//  Stiller Re-Login:
//    POST /api/v1/oauth/refresh-device
//
// ══════════════════════════════════════════════════════════════

// Fortnite Client-ID (öffentlich bekannt, aus dem Spiel selbst)
const _kEpicClientId = 'ec684b8c687f479fadea3cb2ad83f5c6';
const _kRedirectUri  = 'https://localhost/callback';

class FortniteOAuthService {
  static const String _base     = 'https://prod.api-fortnite.com';
  static const Duration _timeout = Duration(seconds: 20);

  static final FortniteOAuthService instance = FortniteOAuthService._();
  FortniteOAuthService._();

  // ──────────────────────────────────────────────────────────
  //  SCHRITT 1: Epic OAuth URL direkt bauen — kein API-Call!
  //
  //  Kein Pro-Plan nötig. Wir bauen die Standard-Epic-OAuth-URL
  //  direkt mit der bekannten Client-ID.
  //  Epic leitet nach dem Login auf redirect_uri?code=... weiter.
  // ──────────────────────────────────────────────────────────

  String buildAuthorizeUrl() {
    final uri = Uri.https('www.epicgames.com', '/id/authorize', {
      'client_id':     _kEpicClientId,
      'response_type': 'code',
      'redirect_uri':  _kRedirectUri,
      'scope':         'basic_profile friends_list presence',
    });
    dev.log('🔗 Authorize URL: $uri', name: 'OrbitOAuth');
    return uri.toString();
  }

  // ──────────────────────────────────────────────────────────
  //  SCHRITT 2: Code gegen Fortnite-Token tauschen
  //  POST /api/v1/oauth/link
  //  Fallback: POST /api/v1/oauth/exchange-code
  // ──────────────────────────────────────────────────────────

  Future<OAuthResult?> linkWithCode(String code) async {
    dev.log('🔗 linkWithCode…', name: 'OrbitOAuth');

    // Versuch 1: /oauth/link
    try {
      final res = await http
          .post(
            Uri.parse('$_base/api/v1/oauth/link'),
            headers: {..._headers(), 'Content-Type': 'application/json'},
            body: jsonEncode({
              'code':         code,
              'redirect_uri': _kRedirectUri,
            }),
          )
          .timeout(_timeout);

      dev.log('link → HTTP ${res.statusCode}\n${res.body}', name: 'OrbitOAuth');

      if (res.statusCode == 200) return _parseResult(res.body);
    } catch (e) {
      dev.log('❌ link Fehler: $e', name: 'OrbitOAuth');
    }

    // Versuch 2: /oauth/exchange-code
    dev.log('🔄 Fallback: exchange-code…', name: 'OrbitOAuth');
    try {
      final res = await http
          .post(
            Uri.parse('$_base/api/v1/oauth/exchange-code'),
            headers: {..._headers(), 'Content-Type': 'application/json'},
            body: jsonEncode({
              'code':         code,
              'redirect_uri': _kRedirectUri,
            }),
          )
          .timeout(_timeout);

      dev.log(
        'exchange-code → HTTP ${res.statusCode}\n${res.body}',
        name: 'OrbitOAuth',
      );

      if (res.statusCode == 200) return _parseResult(res.body);
    } catch (e) {
      dev.log('❌ exchange-code Fehler: $e', name: 'OrbitOAuth');
    }

    return null;
  }

  // ──────────────────────────────────────────────────────────
  //  Stiller Re-Login
  //  POST /api/v1/oauth/refresh-device
  // ──────────────────────────────────────────────────────────

  Future<bool> refreshDevice() async {
    final accountId = AccountStore.fortniteAccountId;
    final deviceId  = AccountStore.fortniteDeviceId;
    final secret    = AccountStore.fortniteDeviceSecret;

    if (accountId == null || deviceId == null || secret == null) {
      dev.log('❌ refreshDevice: keine Device-Daten', name: 'OrbitOAuth');
      return false;
    }

    dev.log('🔄 refreshDevice für $accountId…', name: 'OrbitOAuth');
    try {
      final res = await http
          .post(
            Uri.parse('$_base/api/v1/oauth/refresh-device'),
            headers: {..._headers(), 'Content-Type': 'application/json'},
            body: jsonEncode({
              'accountId': accountId,
              'deviceId':  deviceId,
              'secret':    secret,
            }),
          )
          .timeout(_timeout);

      dev.log('refresh-device → HTTP ${res.statusCode}', name: 'OrbitOAuth');
      if (res.statusCode != 200) return false;

      final result = _parseResult(res.body);
      if (result?.token != null) {
        await AccountStore.updateToken(
          token:       result!.token!,
          tokenExpiry: result.tokenExpiry,
        );
        dev.log('✅ Token still erneuert', name: 'OrbitOAuth');
        return true;
      }
      return false;
    } catch (e) {
      dev.log('❌ refreshDevice Fehler: $e', name: 'OrbitOAuth');
      return false;
    }
  }

  // ──────────────────────────────────────────────────────────
  //  JSON-Parsing
  // ──────────────────────────────────────────────────────────

  OAuthResult? _parseResult(String body) {
    try {
      dynamic json = jsonDecode(body);
      if (json is Map && json.containsKey('data')) json = json['data'] ?? json;
      if (json is! Map<String, dynamic>) return null;

      String? findStr(List<String> keys) {
        for (final k in keys) {
          final v = json[k];
          if (v is String && v.isNotEmpty) return v;
        }
        return null;
      }

      final token       = findStr(['token', 'access_token', 'accessToken']);
      final accountId   = findStr(['accountId', 'account_id', 'id']);
      final displayName = findStr([
        'displayName', 'display_name', 'username', 'name',
      ]);

      // DeviceAuth
      String? deviceId;
      String? deviceSecret;
      final deviceAuth = json['deviceAuth'] as Map?;
      if (deviceAuth != null) {
        deviceId     = deviceAuth['deviceId']  as String? ??
                       deviceAuth['device_id'] as String?;
        deviceSecret = deviceAuth['secret']    as String?;
      } else {
        deviceId     = json['deviceId']  as String? ??
                       json['device_id'] as String?;
        deviceSecret = json['secret']    as String?;
      }

      // Token-Ablaufzeit
      DateTime? expiry;
      final expiresAt = json['expiresAt']  as String? ??
                        json['expires_at'] as String?;
      if (expiresAt != null) {
        try { expiry = DateTime.parse(expiresAt); } catch (_) {}
      }
      final expiresIn = json['expiresIn'] as int? ??
                        json['expires_in'] as int?;
      if (expiry == null && expiresIn != null) {
        expiry = DateTime.now().add(Duration(seconds: expiresIn));
      }

      if (token == null) {
        dev.log('❌ Kein Token. Keys: ${json.keys}', name: 'OrbitOAuth');
        return null;
      }

      dev.log(
        '✅ Token erhalten: accountId=$accountId '
        'displayName=$displayName hasDevice=${deviceId != null}',
        name: 'OrbitOAuth',
      );

      return OAuthResult(
        token:        token,
        accountId:    accountId,
        displayName:  displayName,
        tokenExpiry:  expiry,
        deviceId:     deviceId,
        deviceSecret: deviceSecret,
      );
    } catch (e) {
      dev.log('❌ _parseResult Fehler: $e', name: 'OrbitOAuth');
      return null;
    }
  }

  Map<String, String> _headers() => {
    'Authorization': 'Bearer ${ApiKeys.apiFortnite}',
    'X-Api-Key':     ApiKeys.apiFortnite,
    'api-key':       ApiKeys.apiFortnite,
    'Accept':        'application/json',
  };
}

class OAuthResult {
  final String?   token;
  final String?   accountId;
  final String?   displayName;
  final DateTime? tokenExpiry;
  final String?   deviceId;
  final String?   deviceSecret;

  const OAuthResult({
    this.token,
    this.accountId,
    this.displayName,
    this.tokenExpiry,
    this.deviceId,
    this.deviceSecret,
  });
}
