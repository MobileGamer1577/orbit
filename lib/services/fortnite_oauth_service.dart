import 'dart:async';
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
//  ── DEVICE CODE FLOW (der richtige Flow für mobile Apps) ──
//
//  1. GET  /api/v1/oauth/get-token
//     → Gibt flowId + eine Epic-Login-URL zurück
//     → Kein redirectUri, kein Code-Kopieren nötig
//
//  2. App öffnet URL im Browser, User meldet sich an
//
//  3. App pollt automatisch alle 3s:
//     POST /api/v1/oauth/complete  { flowId }
//     → 202 = noch ausstehend (weiter pollen)
//     → 200 = fertig! Token + DeviceAuth zurück
//
//  4. Speichern: token, accountId, deviceId, secret
//
//  5. Stiller Re-Login (kein Browser nötig):
//     POST /api/v1/oauth/refresh-device { accountId, deviceId, secret }
//
//  ── WARUM NICHT authorize-url? ────────────────────────────
//
//  authorize-url braucht eine redirectUri die die App abfangen
//  muss (Deep Link). Der Device Code Flow ist viel einfacher:
//  kein manuelles Code-Kopieren, kein Deep Link nötig,
//  automatisches Polling im Hintergrund.
//
// ══════════════════════════════════════════════════════════════

class FortniteOAuthService {
  static const String _base    = 'https://prod.api-fortnite.com';
  static const Duration _timeout = Duration(seconds: 20);

  static final FortniteOAuthService instance = FortniteOAuthService._();
  FortniteOAuthService._();

  // ──────────────────────────────────────────────────────────
  //  SCHRITT 1: Device Flow starten
  //
  //  Gibt flowId + die URL zurück die der Nutzer öffnen soll.
  //  Danach: pollCompletion() aufrufen.
  // ──────────────────────────────────────────────────────────

  Future<DeviceFlowStart?> startDeviceFlow() async {
    dev.log('🔑 Starte Device Code Flow…', name: 'OrbitOAuth');
    try {
      final res = await http
          .get(
            Uri.parse('$_base/api/v1/oauth/get-token'),
            headers: _headers(),
          )
          .timeout(_timeout);

      dev.log('🔑 get-token → HTTP ${res.statusCode}\n${res.body}',
          name: 'OrbitOAuth');

      if (res.statusCode != 200) {
        dev.log('❌ get-token Fehler: HTTP ${res.statusCode}', name: 'OrbitOAuth');
        return null;
      }

      final json = jsonDecode(res.body);
      if (json is! Map<String, dynamic>) return null;

      // flowId + url aus der Antwort lesen
      final flowId = json['flowId']  as String? ??
                     json['flow_id'] as String? ??
                     json['id']      as String?;

      final url = json['url']            as String? ??
                  json['verificationUrl'] as String? ??
                  json['verification_url'] as String? ??
                  json['loginUrl']        as String? ??
                  json['login_url']       as String?;

      // Manchmal steckt alles in 'data'
      if (flowId == null || url == null) {
        final data = json['data'] as Map<String, dynamic>?;
        if (data != null) {
          final fId = data['flowId']  as String? ?? data['flow_id'] as String?;
          final fUrl = data['url']    as String? ?? data['verificationUrl'] as String?;
          if (fId != null && fUrl != null) {
            dev.log('✅ Device Flow gestartet (data): flowId=$fId', name: 'OrbitOAuth');
            return DeviceFlowStart(flowId: fId, url: fUrl);
          }
        }
        dev.log('❌ Konnte flowId/url nicht lesen. Keys: ${json.keys}',
            name: 'OrbitOAuth');
        return null;
      }

      dev.log('✅ Device Flow gestartet: flowId=$flowId', name: 'OrbitOAuth');
      return DeviceFlowStart(flowId: flowId, url: url);

    } catch (e) {
      dev.log('❌ startDeviceFlow Fehler: $e', name: 'OrbitOAuth');
      return null;
    }
  }

  // ──────────────────────────────────────────────────────────
  //  SCHRITT 2: Auf Nutzer-Login warten (Polling)
  //
  //  Gibt null zurück wenn noch ausstehend (202).
  //  Gibt OAuthResult zurück wenn fertig (200) oder Fehler.
  // ──────────────────────────────────────────────────────────

  Future<OAuthPollResult> pollCompletion(String flowId) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_base/api/v1/oauth/complete'),
            headers: {
              ..._headers(),
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'flowId': flowId}),
          )
          .timeout(_timeout);

      dev.log('🔄 poll complete → HTTP ${res.statusCode}', name: 'OrbitOAuth');

      if (res.statusCode == 202) {
        // Noch ausstehend — weiter pollen
        return OAuthPollResult.pending();
      }

      if (res.statusCode == 429) {
        // Rate limited — kurze Pause, dann weiter
        return OAuthPollResult.rateLimited();
      }

      if (res.statusCode != 200) {
        dev.log('❌ poll → HTTP ${res.statusCode}\n${res.body}', name: 'OrbitOAuth');
        return OAuthPollResult.error('HTTP ${res.statusCode}');
      }

      dev.log('✅ poll → Login erfolgreich!\n${res.body}', name: 'OrbitOAuth');
      final result = _parseTokenResponse(res.body);
      if (result == null) return OAuthPollResult.error('Token konnte nicht gelesen werden');
      return OAuthPollResult.success(result);

    } catch (e) {
      return OAuthPollResult.error('Netzwerkfehler: $e');
    }
  }

  // ──────────────────────────────────────────────────────────
  //  Stiller Re-Login (kein Browser nötig)
  //
  //  Nutzt deviceId + secret aus AccountStore.
  //  Gibt true zurück wenn Token erfolgreich erneuert.
  // ──────────────────────────────────────────────────────────

  Future<bool> refreshDevice() async {
    final accountId = AccountStore.fortniteAccountId;
    final deviceId  = AccountStore.fortniteDeviceId;
    final secret    = AccountStore.fortniteDeviceSecret;

    if (accountId == null || deviceId == null || secret == null) {
      dev.log('❌ refreshDevice: keine Device-Daten gespeichert', name: 'OrbitOAuth');
      return false;
    }

    dev.log('🔄 refreshDevice für $accountId…', name: 'OrbitOAuth');

    try {
      final res = await http
          .post(
            Uri.parse('$_base/api/v1/oauth/refresh-device'),
            headers: {
              ..._headers(),
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'accountId': accountId,
              'deviceId':  deviceId,
              'secret':    secret,
            }),
          )
          .timeout(_timeout);

      dev.log('🔄 refresh-device → HTTP ${res.statusCode}', name: 'OrbitOAuth');

      if (res.statusCode != 200) return false;

      final result = _parseTokenResponse(res.body);
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
  //  Token-Response parsen
  //  (wird aus pollCompletion + refreshDevice genutzt)
  // ──────────────────────────────────────────────────────────

  OAuthResult? _parseTokenResponse(String body) {
    try {
      var json = jsonDecode(body);

      // Manchmal steckt alles in 'data'
      if (json is Map<String, dynamic> && json.containsKey('data')) {
        json = json['data'] ?? json;
      }

      if (json is! Map<String, dynamic>) return null;

      // Token
      final token = json['token']        as String? ??
                    json['access_token'] as String? ??
                    json['accessToken']  as String?;

      // Account-ID
      final accountId = json['accountId']  as String? ??
                        json['account_id'] as String? ??
                        json['id']         as String?;

      // Anzeigename
      final displayName = json['displayName']  as String? ??
                          json['display_name'] as String? ??
                          json['username']     as String?;

      // DeviceAuth für stillen Re-Login
      String? deviceId;
      String? deviceSecret;
      final deviceAuth = json['deviceAuth'] as Map<String, dynamic>?;
      if (deviceAuth != null) {
        deviceId     = deviceAuth['deviceId']  as String? ?? deviceAuth['device_id'] as String?;
        deviceSecret = deviceAuth['secret']    as String?;
      } else {
        // Manchmal direkt im Root
        deviceId     = json['deviceId']  as String? ?? json['device_id'] as String?;
        deviceSecret = json['secret']    as String?;
      }

      // Ablaufzeit
      DateTime? expiry;
      final expiresAt = json['expiresAt']  as String? ?? json['expires_at'] as String?;
      if (expiresAt != null) {
        try { expiry = DateTime.parse(expiresAt); } catch (_) {}
      }
      final expiresIn = json['expiresIn'] as int? ?? json['expires_in'] as int?;
      if (expiry == null && expiresIn != null) {
        expiry = DateTime.now().add(Duration(seconds: expiresIn));
      }

      if (token == null || token.isEmpty) {
        dev.log('❌ Kein Token in Antwort. Keys: ${json.keys}', name: 'OrbitOAuth');
        return null;
      }

      return OAuthResult(
        token:        token,
        accountId:    accountId,
        displayName:  displayName,
        tokenExpiry:  expiry,
        deviceId:     deviceId,
        deviceSecret: deviceSecret,
      );

    } catch (e) {
      dev.log('❌ _parseTokenResponse Fehler: $e', name: 'OrbitOAuth');
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

// ══════════════════════════════════════════════════════════════
//  Datenklassen
// ══════════════════════════════════════════════════════════════

class DeviceFlowStart {
  final String flowId;
  final String url;
  const DeviceFlowStart({required this.flowId, required this.url});
}

class OAuthResult {
  final String?   token;
  final String?   accountId;
  final String?   displayName;
  final DateTime? tokenExpiry;
  final String?   deviceId;
  final String?   deviceSecret;

  const OAuthResult({
    this.token, this.accountId, this.displayName,
    this.tokenExpiry, this.deviceId, this.deviceSecret,
  });
}

enum _PollStatus { pending, success, error, rateLimited }

class OAuthPollResult {
  final _PollStatus _status;
  final OAuthResult? result;
  final String?      errorMessage;

  OAuthPollResult._({required _PollStatus status, this.result, this.errorMessage})
      : _status = status;

  factory OAuthPollResult.pending()              => OAuthPollResult._(status: _PollStatus.pending);
  factory OAuthPollResult.rateLimited()          => OAuthPollResult._(status: _PollStatus.rateLimited);
  factory OAuthPollResult.success(OAuthResult r) => OAuthPollResult._(status: _PollStatus.success, result: r);
  factory OAuthPollResult.error(String msg)      => OAuthPollResult._(status: _PollStatus.error, errorMessage: msg);

  bool get isPending     => _status == _PollStatus.pending || _status == _PollStatus.rateLimited;
  bool get isSuccess     => _status == _PollStatus.success;
  bool get isError       => _status == _PollStatus.error;
}
