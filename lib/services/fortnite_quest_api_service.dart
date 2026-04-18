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
//  ── WARUM ES VORHER NICHT FUNKTIONIERT HAT ────────────────
//
//  Problem 1: Falscher Endpunkt — wir nutzten /api/v3/quests
//             aber der richtige ist /api/v2/quests/{accountId}
//
//  Problem 2: Fehlender Header — der Endpunkt braucht zwingend
//             "x-fortnite-token: <oauth-token>" im Request.
//             Das ist kein API-Key, sondern ein nutzerspezifischer
//             OAuth-Token von Epic Games.
//
//  ── LÖSUNG ────────────────────────────────────────────────
//
//  Der Nutzer loggt sich einmalig über den ConnectionsScreen ein.
//  Das OAuth-Token wird in AccountStore gespeichert.
//  Dieser Service liest das Token und nutzt es als Header.
//  Bei Ablauf wird das Token automatisch erneuert.
//
//  ── DEBUGGING ─────────────────────────────────────────────
//
//  _debugMode = true → rohe API-Antwort im Logcat
//  Android Studio → Logcat → Filter: "OrbitQuestAPI"
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
  //  Benötigt: AccountStore.fortniteAccountId + fortniteToken
  //  Endpunkt: GET /api/v2/quests/{accountId}
  //  Header:   x-fortnite-token: <token>
  // ──────────────────────────────────────────────────────────

  Future<QuestApiResponse> fetchQuests({String language = 'en'}) async {

    // 1. Kein Account verbunden?
    final accountId = AccountStore.fortniteAccountId;
    if (accountId == null || accountId.isEmpty) {
      return QuestApiResponse.error('no_account');
    }

    // 2. Token prüfen & ggf. erneuern
    final token = await _getValidToken();
    if (token == null) {
      return QuestApiResponse.error('token_expired');
    }

    // 3. Request bauen
    final langCode = language == 'de' ? 'de-DE' : 'en-US';
    final uri = Uri.parse('$_baseUrl/api/v2/quests/$accountId')
        .replace(queryParameters: {'language': langCode, 'lang': language});

    dev.log('📡 Lade Quests: $uri', name: 'OrbitQuestAPI');

    try {
      final res = await http
          .get(uri, headers: _headers(token))
          .timeout(_timeout);

      dev.log('📥 HTTP ${res.statusCode}', name: 'OrbitQuestAPI');
      if (_debugMode) _logPreview(res.body, 'Quests-Antwort');

      switch (res.statusCode) {
        case 200:
          return _parseResponse(res.body, language: language);

        case 401:
          // Token abgelaufen → einmal refreshen und nochmal probieren
          dev.log('🔄 Token abgelaufen, versuche Refresh…',
              name: 'OrbitQuestAPI');
          final refreshed = await FortniteOAuthService.instance.refreshDevice();
          if (!refreshed) {
            return QuestApiResponse.error('token_expired');
          }
          // Zweiter Versuch nach Refresh
          final newToken = AccountStore.fortniteToken;
          if (newToken == null) return QuestApiResponse.error('token_expired');
          final res2 = await http
              .get(uri, headers: _headers(newToken))
              .timeout(_timeout);
          if (res2.statusCode == 200) {
            return _parseResponse(res2.body, language: language);
          }
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
  //  Token validieren / erneuern
  // ──────────────────────────────────────────────────────────

  Future<String?> _getValidToken() async {
    if (AccountStore.isFortniteTokenValid) {
      return AccountStore.fortniteToken;
    }
    // Token abgelaufen → refresh versuchen
    dev.log('🔄 Token nicht mehr gültig, refresh…', name: 'OrbitQuestAPI');
    final refreshed = await FortniteOAuthService.instance.refreshDevice();
    if (refreshed) return AccountStore.fortniteToken;
    return null;
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
        'Setze _debugMode=true in fortnite_quest_api_service.dart.',
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

  Map<String, String> _headers(String fortniteToken) => {
    'Authorization':    'Bearer ${ApiKeys.apiFortnite}',
    'X-Api-Key':        ApiKeys.apiFortnite,
    'api-key':          ApiKeys.apiFortnite,
    'x-fortnite-token': fortniteToken,  // ← Das war der fehlende Header!
    'Accept':           'application/json',
    'Content-Type':     'application/json',
  };

  String _sectionLabel(String key) {
    const m = {
      'weekly':    'Wöchentlich',
      'daily':     'Täglich',
      'battlePass':'Battle Pass',
      'story':     'Story',
      'milestone': 'Meilensteine',
    };
    return m[key] ?? key;
  }

  void _logPreview(String body, String label) {
    final preview = body.length > 800
        ? '${body.substring(0, 800)}...'
        : body;
    dev.log('📄 $label:\n$preview', name: 'OrbitQuestAPI');
  }
}
