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
//  Verwaltet den Epic-OAuth-Login über api-fortnite.com.
//
//  ── LOGIN-FLOW ────────────────────────────────────────────
//
//  1. getAuthorizeUrl()     → gibt die Epic-Login-URL zurück
//  2. Nutzer öffnet URL im Browser → meldet sich an
//  3. Epic zeigt nach Login einen "Authorization Code"
//  4. exchangeCode(code)    → tauscht Code gegen Token
//  5. Token + AccountId werden lokal gespeichert
//  6. refreshToken()        → erneuert den Token bei Ablauf
//
//  ── WO WIRD DAS GENUTZT? ─────────────────────────────────
//
//  connections_screen.dart  → Login-UI
//  fortnite_quest_api_service.dart → Token für API-Calls
//
// ══════════════════════════════════════════════════════════════

class FortniteOAuthService {
  static const String _base    = 'https://prod.api-fortnite.com';
  static const Duration _timeout = Duration(seconds: 20);

  static final FortniteOAuthService instance = FortniteOAuthService._();
  FortniteOAuthService._();

  // ──────────────────────────────────────────────────────────
  //  SCHRITT 1: Authorize-URL holen
  //
  //  Gibt die URL zurück die der Nutzer im Browser öffnen soll.
  //  Wenn ein Fehler auftritt → null
  // ──────────────────────────────────────────────────────────

  Future<String?> getAuthorizeUrl() async {
    try {
      final res = await http
          .get(
            Uri.parse('$_base/api/v1/oauth/authorize-url'),
            headers: _headers(),
          )
          .timeout(_timeout);

      dev.log('🔑 authorize-url → HTTP ${res.statusCode}\n${res.body}',
          name: 'OrbitOAuth');

      if (res.statusCode != 200) return null;

      final json = jsonDecode(res.body);

      // Format A: { "url": "https://..." }
      if (json is Map) {
        final url = json['url'] as String? ??
                    json['authorizeUrl'] as String? ??
                    json['authorize_url'] as String? ??
                    json['redirectUrl'] as String? ??
                    json['redirect_url'] as String?;
        if (url != null && url.isNotEmpty) return url;

        // Format B: { "data": { "url": "..." } }
        final data = json['data'] as Map?;
        if (data != null) {
          final dataUrl = data['url'] as String? ?? data['authorizeUrl'] as String?;
          if (dataUrl != null) return dataUrl;
        }
      }

      // Format C: nur der String selbst
      if (json is String && json.startsWith('http')) return json;

      dev.log('❌ Unbekannte authorize-url Antwort: $json', name: 'OrbitOAuth');
      return null;

    } catch (e) {
      dev.log('❌ authorize-url Fehler: $e', name: 'OrbitOAuth');
      return null;
    }
  }

  // ──────────────────────────────────────────────────────────
  //  SCHRITT 2: Code gegen Token tauschen
  //
  //  [code] = Der Authorization-Code den der Nutzer nach
  //           dem Epic-Login erhält/eingibt.
  //
  //  Gibt OAuthResult zurück oder null bei Fehler.
  // ──────────────────────────────────────────────────────────

  Future<OAuthResult?> exchangeCode(String code) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_base/api/v1/oauth/exchange-code'),
            headers: {
              ..._headers(),
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'code':          code.trim(),
              'exchangeCode':  code.trim(), // Beide Felder probieren
            }),
          )
          .timeout(_timeout);

      dev.log('🔑 exchange-code → HTTP ${res.statusCode}\n${res.body}',
          name: 'OrbitOAuth');

      if (res.statusCode != 200) {
        final err = _extractError(res.body);
        return OAuthResult.error(err ?? 'HTTP ${res.statusCode}');
      }

      return _parseTokenResponse(res.body);

    } catch (e) {
      return OAuthResult.error('Netzwerkfehler: $e');
    }
  }

  // ──────────────────────────────────────────────────────────
  //  Token erneuern (wird vom QuestService auto. aufgerufen)
  // ──────────────────────────────────────────────────────────

  Future<bool> refreshToken() async {
    final currentToken = AccountStore.fortniteToken;
    if (currentToken == null) return false;

    try {
      final res = await http
          .post(
            Uri.parse('$_base/api/v1/oauth/refresh-token'),
            headers: {
              ..._headers(),
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'token':        currentToken,
              'refreshToken': currentToken, // Beide Felder probieren
            }),
          )
          .timeout(_timeout);

      dev.log('🔑 refresh-token → HTTP ${res.statusCode}', name: 'OrbitOAuth');

      if (res.statusCode != 200) return false;

      final result = _parseTokenResponse(res.body);
      if (result?.token != null) {
        await AccountStore.updateToken(
          token:       result!.token!,
          tokenExpiry: result.tokenExpiry,
        );
        return true;
      }
      return false;

    } catch (e) {
      dev.log('❌ refresh-token Fehler: $e', name: 'OrbitOAuth');
      return false;
    }
  }

  // ──────────────────────────────────────────────────────────
  //  Parsing & Hilfsmethoden
  // ──────────────────────────────────────────────────────────

  OAuthResult? _parseTokenResponse(String body) {
    try {
      final json = jsonDecode(body);
      if (json is! Map) return OAuthResult.error('Unbekanntes Format');

      final map = json as Map<String, dynamic>;

      // Token
      final token = map['token']        as String? ??
                    map['access_token'] as String? ??
                    map['accessToken']  as String?;

      // Account-ID
      final accountId = map['accountId']  as String? ??
                        map['account_id'] as String? ??
                        map['id']         as String?;

      // Anzeigename
      final displayName = map['displayName'] as String? ??
                          map['display_name'] as String? ??
                          map['username']     as String?;

      // Ablaufzeit
      DateTime? expiry;
      final expiresAt = map['expiresAt']  as String? ??
                        map['expires_at'] as String?;
      if (expiresAt != null) {
        try { expiry = DateTime.parse(expiresAt); } catch (_) {}
      }
      final expiresIn = map['expiresIn'] as int? ?? map['expires_in'] as int?;
      if (expiry == null && expiresIn != null) {
        expiry = DateTime.now().add(Duration(seconds: expiresIn));
      }

      if (token == null || token.isEmpty) {
        // Vielleicht steckt alles in 'data'?
        final data = map['data'] as Map<String, dynamic>?;
        if (data != null) return _parseTokenResponse(jsonEncode(data));
        return OAuthResult.error('Kein Token in der Antwort');
      }

      return OAuthResult(
        token:       token,
        accountId:   accountId,
        displayName: displayName,
        tokenExpiry: expiry,
      );

    } catch (e) {
      return OAuthResult.error('Parse-Fehler: $e');
    }
  }

  String? _extractError(String body) {
    try {
      final json = jsonDecode(body);
      if (json is Map) {
        return json['error'] as String? ??
               json['message'] as String? ??
               json['detail'] as String?;
      }
    } catch (_) {}
    return null;
  }

  Map<String, String> _headers() => {
    'Authorization': 'Bearer ${ApiKeys.apiFortnite}',
    'X-Api-Key':     ApiKeys.apiFortnite,
    'api-key':       ApiKeys.apiFortnite,
  };
}

// ──────────────────────────────────────────────────────────────
//  Ergebnis-Klasse
// ──────────────────────────────────────────────────────────────

class OAuthResult {
  final String?   token;
  final String?   accountId;
  final String?   displayName;
  final DateTime? tokenExpiry;
  final String?   errorMessage;

  bool get isSuccess => token != null && errorMessage == null;

  const OAuthResult({
    this.token,
    this.accountId,
    this.displayName,
    this.tokenExpiry,
    this.errorMessage,
  });

  factory OAuthResult.error(String msg) => OAuthResult(errorMessage: msg);
}
