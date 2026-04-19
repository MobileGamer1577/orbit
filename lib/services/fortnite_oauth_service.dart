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
// ══════════════════════════════════════════════════════════════

class FortniteOAuthService {
  static const String _base = 'https://prod.api-fortnite.com';
  static const Duration _timeout = Duration(seconds: 20);

  static final FortniteOAuthService instance = FortniteOAuthService._();
  FortniteOAuthService._();

  // ──────────────────────────────────────────────────────────
  //  SCHRITT 1: Device Flow starten
  // ──────────────────────────────────────────────────────────

  Future<DeviceFlowStart?> startDeviceFlow() async {
    dev.log('🔑 Starte Device Code Flow…', name: 'OrbitOAuth');
    try {
      final res = await http
          .get(Uri.parse('$_base/api/v1/oauth/get-token'), headers: _headers())
          .timeout(_timeout);

      // ── IMMER den vollen Body loggen ──────────────────────
      dev.log(
        '🔑 get-token → HTTP ${res.statusCode}\n'
        'Body: ${res.body}',
        name: 'OrbitOAuth',
      );

      if (res.statusCode != 200) {
        dev.log(
          '❌ get-token Fehler: HTTP ${res.statusCode}',
          name: 'OrbitOAuth',
        );
        // Fehlermeldung mit echtem Status-Code zurückgeben
        return DeviceFlowStart.error('HTTP ${res.statusCode}: ${res.body}');
      }

      final decoded = jsonDecode(res.body);

      // Manchmal ist alles in 'data' gewrappt
      final json =
          (decoded is Map<String, dynamic> && decoded.containsKey('data'))
          ? (decoded['data'] as Map<String, dynamic>? ?? decoded)
          : (decoded is Map<String, dynamic> ? decoded : null);

      if (json == null) {
        dev.log('❌ Unerwartetes JSON-Format: $decoded', name: 'OrbitOAuth');
        return DeviceFlowStart.error('Unerwartetes Antwort-Format');
      }

      dev.log(
        '🔍 JSON-Keys in Antwort: ${json.keys.toList()}',
        name: 'OrbitOAuth',
      );

      // ── flowId: viele mögliche Feldnamen ─────────────────
      final flowId = _findString(json, [
        'flowId',
        'flow_id',
        'id',
        'token',
        'code',
        'sessionId',
        'session_id',
      ]);

      // ── url: viele mögliche Feldnamen ───────────────────
      final url =
          _findString(json, [
            'url',
            'verificationUrl',
            'verification_url',
            'loginUrl',
            'login_url',
            'authUrl',
            'auth_url',
            'redirectUrl',
            'redirect_url',
            'link',
            'href',
            'uri',
          ]) ??
          _findUrlAnywhere(json);

      if (flowId == null) {
        dev.log(
          '❌ Kein flowId gefunden. Alle Felder:\n${_prettyKeys(json)}',
          name: 'OrbitOAuth',
        );
        return DeviceFlowStart.error(
          'Feld "flowId" nicht in API-Antwort gefunden.\n'
          'Felder: ${json.keys.take(8).join(', ')}',
        );
      }

      if (url == null) {
        dev.log(
          '❌ Keine URL gefunden. Alle Felder:\n${_prettyKeys(json)}',
          name: 'OrbitOAuth',
        );
        return DeviceFlowStart.error(
          'Feld "url" nicht in API-Antwort gefunden.\n'
          'Felder: ${json.keys.take(8).join(', ')}',
        );
      }

      dev.log(
        '✅ Device Flow gestartet: flowId=$flowId url=$url',
        name: 'OrbitOAuth',
      );
      return DeviceFlowStart(flowId: flowId, url: url);
    } on http.ClientException catch (e) {
      dev.log('❌ Netzwerkfehler: $e', name: 'OrbitOAuth');
      return DeviceFlowStart.error('Netzwerkfehler: $e');
    } catch (e) {
      dev.log('❌ startDeviceFlow Fehler: $e', name: 'OrbitOAuth');
      return DeviceFlowStart.error('Fehler: $e');
    }
  }

  // ──────────────────────────────────────────────────────────
  //  SCHRITT 2: Auf Nutzer-Login warten (Polling)
  // ──────────────────────────────────────────────────────────

  Future<OAuthPollResult> pollCompletion(String flowId) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_base/api/v1/oauth/complete'),
            headers: {..._headers(), 'Content-Type': 'application/json'},
            body: jsonEncode({'flowId': flowId}),
          )
          .timeout(_timeout);

      dev.log('🔄 poll complete → HTTP ${res.statusCode}', name: 'OrbitOAuth');

      if (res.statusCode == 202) return OAuthPollResult.pending();
      if (res.statusCode == 429) return OAuthPollResult.rateLimited();

      if (res.statusCode != 200) {
        dev.log(
          '❌ poll → HTTP ${res.statusCode}\n${res.body}',
          name: 'OrbitOAuth',
        );
        return OAuthPollResult.error('HTTP ${res.statusCode}');
      }

      dev.log('✅ poll → Login erfolgreich!\n${res.body}', name: 'OrbitOAuth');
      final result = _parseTokenResponse(res.body);
      if (result == null)
        return OAuthPollResult.error('Token konnte nicht gelesen werden');
      return OAuthPollResult.success(result);
    } on http.ClientException catch (e) {
      // "Software caused connection abort" tritt auf wenn Android die
      // HTTP-Verbindung abbricht sobald der User vom Browser zurueckkommt.
      // Das ist kein echter Fehler — einfach weiterpollen.
      dev.log('⚠️ poll ClientException (ignoriert): $e', name: 'OrbitOAuth');
      return OAuthPollResult.pending();
    } on TimeoutException catch (_) {
      dev.log('⚠️ poll Timeout (ignoriert)', name: 'OrbitOAuth');
      return OAuthPollResult.pending();
    } catch (e) {
      // Alle anderen Exceptions (SocketException, etc.) ebenfalls pending —
      // der Login-Flow soll nicht wegen eines kurzen Verbindungsabbruchs
      // beim App-Wechsel abbrechen.
      dev.log('⚠️ poll Exception (ignoriert): $e', name: 'OrbitOAuth');
      return OAuthPollResult.pending();
    }
  }

  // ──────────────────────────────────────────────────────────
  //  Stiller Re-Login (kein Browser nötig)
  // ──────────────────────────────────────────────────────────

  Future<bool> refreshDevice() async {
    final accountId = AccountStore.fortniteAccountId;
    final deviceId = AccountStore.fortniteDeviceId;
    final secret = AccountStore.fortniteDeviceSecret;

    if (accountId == null || deviceId == null || secret == null) {
      dev.log(
        '❌ refreshDevice: keine Device-Daten gespeichert',
        name: 'OrbitOAuth',
      );
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
              'deviceId': deviceId,
              'secret': secret,
            }),
          )
          .timeout(_timeout);

      dev.log('🔄 refresh-device → HTTP ${res.statusCode}', name: 'OrbitOAuth');

      if (res.statusCode != 200) return false;

      final result = _parseTokenResponse(res.body);
      if (result?.token != null) {
        await AccountStore.updateToken(
          token: result!.token!,
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
  // ──────────────────────────────────────────────────────────

  OAuthResult? _parseTokenResponse(String body) {
    try {
      var json = jsonDecode(body);
      if (json is Map<String, dynamic> && json.containsKey('data')) {
        json = json['data'] ?? json;
      }
      if (json is! Map<String, dynamic>) return null;

      final token = _findString(json, ['token', 'access_token', 'accessToken']);

      final accountId = _findString(json, ['accountId', 'account_id', 'id']);
      final displayName = _findString(json, [
        'displayName',
        'display_name',
        'username',
        'name',
      ]);

      String? deviceId;
      String? deviceSecret;
      final deviceAuth = json['deviceAuth'] as Map<String, dynamic>?;
      if (deviceAuth != null) {
        deviceId =
            deviceAuth['deviceId'] as String? ??
            deviceAuth['device_id'] as String?;
        deviceSecret = deviceAuth['secret'] as String?;
      } else {
        deviceId = json['deviceId'] as String? ?? json['device_id'] as String?;
        deviceSecret = json['secret'] as String?;
      }

      DateTime? expiry;
      final expiresAt =
          json['expiresAt'] as String? ?? json['expires_at'] as String?;
      if (expiresAt != null) {
        try {
          expiry = DateTime.parse(expiresAt);
        } catch (_) {}
      }
      final expiresIn = json['expiresIn'] as int? ?? json['expires_in'] as int?;
      if (expiry == null && expiresIn != null) {
        expiry = DateTime.now().add(Duration(seconds: expiresIn));
      }

      if (token == null || token.isEmpty) {
        dev.log(
          '❌ Kein Token in Antwort. Keys: ${json.keys}',
          name: 'OrbitOAuth',
        );
        return null;
      }

      return OAuthResult(
        token: token,
        accountId: accountId,
        displayName: displayName,
        tokenExpiry: expiry,
        deviceId: deviceId,
        deviceSecret: deviceSecret,
      );
    } catch (e) {
      dev.log('❌ _parseTokenResponse Fehler: $e', name: 'OrbitOAuth');
      return null;
    }
  }

  // ──────────────────────────────────────────────────────────
  //  Hilfsmethoden
  // ──────────────────────────────────────────────────────────

  /// Sucht den ersten nicht-leeren String-Wert für die gegebenen Keys.
  String? _findString(Map<String, dynamic> json, List<String> keys) {
    for (final k in keys) {
      final v = json[k];
      if (v is String && v.isNotEmpty) return v;
    }
    return null;
  }

  /// Sucht irgendwo im JSON nach einem String-Wert der wie eine URL aussieht.
  String? _findUrlAnywhere(Map<String, dynamic> json) {
    for (final v in json.values) {
      if (v is String &&
          (v.startsWith('http://') || v.startsWith('https://'))) {
        return v;
      }
    }
    return null;
  }

  String _prettyKeys(Map<String, dynamic> json) {
    return json.entries
        .map((e) => '  "${e.key}": ${e.value.runtimeType}')
        .join('\n');
  }

  Map<String, String> _headers() => {
    'Authorization': 'Bearer ${ApiKeys.apiFortnite}',
    'X-Api-Key': ApiKeys.apiFortnite,
    'api-key': ApiKeys.apiFortnite,
    'Accept': 'application/json',
  };
}

// ══════════════════════════════════════════════════════════════
//  Datenklassen
// ══════════════════════════════════════════════════════════════

class DeviceFlowStart {
  final String? flowId;
  final String? url;
  final String? errorDetails; // null = kein Fehler

  const DeviceFlowStart({
    required this.flowId,
    required this.url,
    this.errorDetails,
  });

  /// Erstellt ein Fehler-Objekt mit Diagnosetext
  factory DeviceFlowStart.error(String details) =>
      DeviceFlowStart(flowId: null, url: null, errorDetails: details);

  bool get hasError => errorDetails != null;
}

class OAuthResult {
  final String? token;
  final String? accountId;
  final String? displayName;
  final DateTime? tokenExpiry;
  final String? deviceId;
  final String? deviceSecret;

  const OAuthResult({
    this.token,
    this.accountId,
    this.displayName,
    this.tokenExpiry,
    this.deviceId,
    this.deviceSecret,
  });
}

enum _PollStatus { pending, success, error, rateLimited }

class OAuthPollResult {
  final _PollStatus _status;
  final OAuthResult? result;
  final String? errorMessage;

  OAuthPollResult._({
    required _PollStatus status,
    this.result,
    this.errorMessage,
  }) : _status = status;

  factory OAuthPollResult.pending() =>
      OAuthPollResult._(status: _PollStatus.pending);
  factory OAuthPollResult.rateLimited() =>
      OAuthPollResult._(status: _PollStatus.rateLimited);
  factory OAuthPollResult.success(OAuthResult r) =>
      OAuthPollResult._(status: _PollStatus.success, result: r);
  factory OAuthPollResult.error(String msg) =>
      OAuthPollResult._(status: _PollStatus.error, errorMessage: msg);

  bool get isPending =>
      _status == _PollStatus.pending || _status == _PollStatus.rateLimited;
  bool get isSuccess => _status == _PollStatus.success;
  bool get isError => _status == _PollStatus.error;
}
