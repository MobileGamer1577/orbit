import 'dart:convert';
import 'dart:developer' as dev;
import 'package:http/http.dart' as http;
import '../config/api_keys.dart';
import '../models/api_quest.dart';
import '../services/fortnite_oauth_service.dart';
import '../storage/account_store.dart';

// ══════════════════════════════════════════════════════════════
//
//  🌐 FORTNITE QUEST API SERVICE
//  Datei: lib/services/fortnite_quest_api_service.dart
//
//  Endpunkt: GET /api/v3/quests/{accountId}
//
//  Strategie:
//    1. Versuch: Nur API-Key (kein x-fortnite-token)
//    2. Versuch: API-Key + x-fortnite-token (falls 401)
//    3. Versuch: Token erneuern via refresh-device, nochmal (falls 401)
//
//  Debugging:
//    _debugMode = true → Logcat Filter: "OrbitQuestAPI"
//
// ══════════════════════════════════════════════════════════════

class FortniteQuestApiService {
  static const String _baseUrl   = 'https://prod.api-fortnite.com';
  static const Duration _timeout = Duration(seconds: 25);

  /// true → rohe API-Antwort im Logcat ausgeben
  static const bool _debugMode = true;

  static final FortniteQuestApiService instance =
      FortniteQuestApiService._();
  FortniteQuestApiService._();

  // ──────────────────────────────────────────────────────────
  //  QUESTS LADEN
  //
  //  Endpunkt: GET /api/v3/quests/{accountId}
  // ──────────────────────────────────────────────────────────

  Future<QuestApiResponse> fetchQuests({String language = 'en'}) async {

    // 1. Kein Account verbunden?
    final accountId = AccountStore.fortniteAccountId;
    if (accountId == null || accountId.isEmpty) {
      return QuestApiResponse.error('no_account');
    }

    // 2. Token laden (optional — wir versuchen erst ohne)
    final token = AccountStore.fortniteToken;

    // 3. Request bauen
    final langCode = language == 'de' ? 'de-DE' : 'en-US';
    final uri = Uri.parse('$_baseUrl/api/v3/quests/$accountId')
        .replace(queryParameters: {'language': langCode, 'lang': language});

    dev.log('📡 Lade Quests: $uri', name: 'OrbitQuestAPI');

    try {
      // ── Versuch 1: Nur API-Key ──────────────────────────
      var res = await http
          .get(uri, headers: _headersApiKeyOnly())
          .timeout(_timeout);

      dev.log('📥 V1 (API-Key only): HTTP ${res.statusCode}', name: 'OrbitQuestAPI');
      if (_debugMode) _logPreview(res.body, 'V1 Antwort');

      // ── Versuch 2: API-Key + fortnite-token ─────────────
      if (res.statusCode == 401 && token != null && token.isNotEmpty) {
        dev.log('🔄 V2: Versuche mit fortnite-token…', name: 'OrbitQuestAPI');
        res = await http
            .get(uri, headers: _headers(token))
            .timeout(_timeout);
        dev.log('📥 V2 (mit token): HTTP ${res.statusCode}', name: 'OrbitQuestAPI');
        if (_debugMode) _logPreview(res.body, 'V2 Antwort');
      }

      // ── Versuch 3: Token erneuern ────────────────────────
      if (res.statusCode == 401) {
        dev.log('🔄 V3: Token erneuern via refresh-device…', name: 'OrbitQuestAPI');
        final refreshed = await FortniteOAuthService.instance.refreshDevice();
        if (refreshed) {
          final newToken = AccountStore.fortniteToken;
          if (newToken != null) {
            res = await http
                .get(uri, headers: _headers(newToken))
                .timeout(_timeout);
            dev.log('📥 V3 (refresh): HTTP ${res.statusCode}', name: 'OrbitQuestAPI');
            if (_debugMode) _logPreview(res.body, 'V3 Antwort');
          }
        }
      }

      // ── Antwort auswerten ────────────────────────────────
      switch (res.statusCode) {
        case 200:
          return _parseResponse(res.body, language: language);
        case 401:
          return QuestApiResponse.error('token_expired');
        case 403:
          return QuestApiResponse.error(
            'Zugriff verweigert (HTTP 403).\n'
            'Prüfe deinen API-Key in lib/config/api_keys.dart.',
          );
        case 404:
          return QuestApiResponse.error('account_invalid');
        default:
          return QuestApiResponse.error('HTTP ${res.statusCode}');
      }

    } on Exception catch (e) {
      return QuestApiResponse.error('Netzwerkfehler: $e');
    }
  }

  // ──────────────────────────────────────────────────────────
  //  JSON-Parsing
  // ──────────────────────────────────────────────────────────

  QuestApiResponse _parseResponse(String body, {String language = 'en'}) {
    try {
      final decoded = jsonDecode(body);

      if (decoded is List) {
        return _fromList(
            decoded.whereType<Map<String, dynamic>>().toList(), language);
      }

      if (decoded is! Map<String, dynamic>) {
        return QuestApiResponse.error(
            'Unbekanntes JSON-Format: ${decoded.runtimeType}');
      }

      final json = decoded;

      // Fehler aus der API selbst
      final ok = json['result'] ?? json['success'] ?? json['ok'];
      if (ok == false || ok == 'error') {
        return QuestApiResponse.error(
          json['error'] as String? ?? json['message'] as String? ?? 'API-Fehler',
        );
      }

      // Format A: bekannte List-Keys
      for (final key in ['quests', 'challenges', 'data', 'items']) {
        final raw = json[key];
        if (raw is List && raw.isNotEmpty) {
          dev.log('📦 Format A key="$key" ${raw.length} Einträge',
              name: 'OrbitQuestAPI');
          return _fromList(
              raw.whereType<Map<String, dynamic>>().toList(), language);
        }
      }

      // Format B: Nach Typ gruppiert (weekly, daily, ...)
      final typeKeys = [
        'weekly', 'daily', 'battlePass', 'story', 'milestone',
        'punchcard', 'seasonal', 'limited', 'event',
      ];
      final combined = <Map<String, dynamic>>[];
      for (final key in typeKeys) {
        if (json[key] is List) {
          for (final item in (json[key] as List)) {
            if (item is Map<String, dynamic>) {
              final entry = Map<String, dynamic>.from(item);
              entry.putIfAbsent('section', () => _sectionLabel(key));
              combined.add(entry);
            }
          }
        }
      }
      if (combined.isNotEmpty) {
        dev.log('📦 Format B ${combined.length} Quests', name: 'OrbitQuestAPI');
        return _fromList(combined, language);
      }

      dev.log('❓ Unbekannte Struktur. Keys: ${json.keys.join(", ")}',
          name: 'OrbitQuestAPI');
      return QuestApiResponse.error(
        'Unbekannte API-Struktur.\nKeys: ${json.keys.join(", ")}\n'
        'Logcat Filter: "OrbitQuestAPI" für Details.',
      );

    } on FormatException catch (e) {
      return QuestApiResponse.error('JSON-Fehler: $e');
    } catch (e) {
      return QuestApiResponse.error('Parse-Fehler: $e');
    }
  }

  QuestApiResponse _fromList(List<Map<String, dynamic>> raw, String language) {
    final quests = raw
        .map((q) => ApiQuest.fromApiJson(q, language))
        .where((q) => q.id.isNotEmpty || q.title.isNotEmpty)
        .toList();
    dev.log('✅ ${quests.length} Quests geparst', name: 'OrbitQuestAPI');
    if (quests.isEmpty) {
      return QuestApiResponse.error(
          'API antwortet, aber keine Quests gefunden.');
    }
    return QuestApiResponse(success: true, quests: quests);
  }

  // ──────────────────────────────────────────────────────────
  //  Hilfsmethoden
  // ──────────────────────────────────────────────────────────

  /// Nur API-Key — kein user-spezifischer Token.
  Map<String, String> _headersApiKeyOnly() => {
    'Authorization': 'Bearer ${ApiKeys.apiFortnite}',
    'X-Api-Key':     ApiKeys.apiFortnite,
    'api-key':       ApiKeys.apiFortnite,
    'Accept':        'application/json',
    'Content-Type':  'application/json',
  };

  /// API-Key + x-fortnite-token.
  Map<String, String> _headers(String fortniteToken) => {
    'Authorization':    'Bearer ${ApiKeys.apiFortnite}',
    'X-Api-Key':        ApiKeys.apiFortnite,
    'api-key':          ApiKeys.apiFortnite,
    'x-fortnite-token': fortniteToken,
    'Accept':           'application/json',
    'Content-Type':     'application/json',
  };

  String _sectionLabel(String key) {
    const m = {
      'weekly':     'Wöchentlich',
      'daily':      'Täglich',
      'battlePass': 'Battle Pass',
      'story':      'Story',
      'milestone':  'Meilensteine',
    };
    return m[key] ?? key;
  }

  void _logPreview(String body, String label) {
    final preview = body.length > 800 ? '${body.substring(0, 800)}...' : body;
    dev.log('📄 $label:\n$preview', name: 'OrbitQuestAPI');
  }
}
