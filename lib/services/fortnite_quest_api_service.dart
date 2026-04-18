import 'dart:convert';
import 'dart:developer' as dev;
import 'package:http/http.dart' as http;
import '../config/api_keys.dart';
import '../models/api_quest.dart';
import '../storage/account_store.dart';

// ══════════════════════════════════════════════════════════════
//
//  🌐 FORTNITE QUEST API SERVICE
//  Datei: lib/services/fortnite_quest_api_service.dart
//
//  Endpunkt: GET /api/v3/quests/{accountId}
//  API: https://prod.api-fortnite.com
//
//  ── WARUM ES VORHER NICHT FUNKTIONIERT HAT ────────────────
//
//  Der Endpunkt braucht ZWINGEND eine accountId im Pfad.
//  Ohne sie → HTTP 404.
//  Die accountId wird über ConnectionsScreen einmalig gespeichert.
//
//  ── ABLAUF ────────────────────────────────────────────────
//
//  1. AccountStore.fortniteAccountId lesen
//  2. Wenn leer → Fehler-Code 'no_account' (UI zeigt Verbinden-Button)
//  3. GET /api/v3/quests/{accountId}
//  4. JSON parsen → ApiQuest-Liste
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
  //
  //  🔍 ACCOUNT-LOOKUP
  //
  //  Wird aus dem ConnectionsScreen aufgerufen.
  //  Endpunkt: GET /api/v1/account/displayName/{displayName}
  //
  //  Gibt null zurück wenn der Account nicht gefunden wurde.
  //
  // ──────────────────────────────────────────────────────────

  Future<({String accountId, String displayName})?> lookupAccount(
    String displayName,
  ) async {
    final uri = Uri.parse(
      '$_baseUrl/api/v1/account/displayName/${Uri.encodeComponent(displayName.trim())}',
    );

    dev.log('🔍 Suche Account: "$displayName"', name: 'OrbitQuestAPI');

    try {
      final res = await http
          .get(uri, headers: _headers())
          .timeout(_timeout);

      dev.log('📥 HTTP ${res.statusCode}', name: 'OrbitQuestAPI');
      if (_debugMode) _logPreview(res.body, 'Account-Antwort');

      if (res.statusCode != 200) return null;

      final json = jsonDecode(res.body);
      String? id;
      String? name;

      if (json is Map) {
        // Format A: { "id": "...", "displayName": "..." }
        id   = json['id']          as String?;
        name = json['displayName'] as String?;

        // Format B: { "account": { "id": "...", ... } }
        if (id == null) {
          final acc = json['account'] as Map?;
          id   = acc?['id']          as String?;
          name = acc?['displayName'] as String?;
        }

        // Format C: { "data": { "id": "...", ... } }
        if (id == null) {
          final data = json['data'] as Map?;
          id   = data?['id']          as String?;
          name = data?['displayName'] as String?;
        }
      }

      if (id != null && id.isNotEmpty) {
        dev.log('✅ Account: ${name ?? displayName} ($id)', name: 'OrbitQuestAPI');
        return (accountId: id, displayName: name ?? displayName);
      }

      dev.log('❌ Kein Account für "$displayName"', name: 'OrbitQuestAPI');
      return null;

    } catch (e) {
      dev.log('❌ Account-Suche Fehler: $e', name: 'OrbitQuestAPI');
      return null;
    }
  }

  // ──────────────────────────────────────────────────────────
  //
  //  📡 QUESTS LADEN
  //
  //  Liest die accountId aus AccountStore.
  //  Wenn kein Account verbunden: Fehlercode 'no_account' →
  //  ApiQuestListScreen zeigt dann den Verbinden-Button.
  //
  // ──────────────────────────────────────────────────────────

  Future<QuestApiResponse> fetchQuests({String language = 'en'}) async {
    final accountId = AccountStore.fortniteAccountId;

    // Kein Account verbunden → spezieller Fehlercode
    if (accountId == null || accountId.isEmpty) {
      return QuestApiResponse.error('no_account');
    }

    final langCode = language == 'de' ? 'de-DE' : 'en-US';
    final uri = Uri.parse('$_baseUrl/api/v3/quests/$accountId')
        .replace(queryParameters: {'language': langCode, 'lang': language});

    dev.log('📡 Lade Quests: $uri', name: 'OrbitQuestAPI');

    try {
      final res = await http
          .get(uri, headers: _headers())
          .timeout(_timeout);

      dev.log('📥 HTTP ${res.statusCode}', name: 'OrbitQuestAPI');
      if (_debugMode) _logPreview(res.body, 'Quests-Antwort');

      switch (res.statusCode) {
        case 200:
          return _parseResponse(res.body, language: language);

        case 401:
        case 403:
          return QuestApiResponse.error(
            'API-Key ungültig (HTTP ${res.statusCode}).\n'
            'Prüfe: lib/config/api_keys.dart → ApiKeys.apiFortnite',
          );

        case 404:
          return QuestApiResponse.error(
            'account_invalid', // Spezieller Fehlercode — zeigt "Neu verbinden"
          );

        default:
          return QuestApiResponse.error('HTTP ${res.statusCode}');
      }

    } on Exception catch (e) {
      return QuestApiResponse.error('Netzwerkfehler: $e');
    }
  }

  // ──────────────────────────────────────────────────────────
  //  JSON-Parsing (mehrere Formate werden unterstützt)
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
          json['error'] as String? ??
          json['message'] as String? ??
          'API meldet Fehler.',
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
        'Unbekannte API-Struktur.\n'
        'Keys: ${json.keys.join(", ")}\n'
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
      return QuestApiResponse.error('API antwortet, aber keine Quests gefunden.');
    }
    return QuestApiResponse(success: true, quests: quests);
  }

  // ──────────────────────────────────────────────────────────
  //  Hilfsmethoden
  // ──────────────────────────────────────────────────────────

  Map<String, String> _headers() => {
    'Authorization': 'Bearer ${ApiKeys.apiFortnite}',
    'X-Api-Key':     ApiKeys.apiFortnite,
    'api-key':       ApiKeys.apiFortnite,
    'Accept':        'application/json',
    'Content-Type':  'application/json',
    'User-Agent':    'Orbit-App/0.3.1',
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
    final preview = body.length > 600 ? '${body.substring(0, 600)}...' : body;
    dev.log('📄 $label:\n$preview', name: 'OrbitQuestAPI');
  }
}
