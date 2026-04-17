import 'dart:convert';
import 'dart:developer' as dev;
import 'package:http/http.dart' as http;
import '../models/api_quest.dart';

// ══════════════════════════════════════════════════════════════
//
//  🌐 FORTNITE QUEST API SERVICE  —  VOLLSTÄNDIGE IMPLEMENTIERUNG
//  Datei: lib/services/fortnite_quest_api_service.dart
//
//  API-Anbieter : https://prod.api-fortnite.com
//  Dashboard    : https://www.api-fortnite.com/login
//  Swagger-Docs : https://prod.api-fortnite.com/swagger/index.html
//
//  ┌─────────────────────────────────────────────────────────┐
//  │  WIE DIESE DATEI FUNKTIONIERT                           │
//  │                                                         │
//  │  1. fetchQuests() aufrufen                              │
//  │  2. Service versucht 3 Endpunkte nacheinander:          │
//  │     a) /api/v2/challenges  (allgemeine Challenges)      │
//  │     b) /api/v1/challenges  (ältere Version)             │
//  │     c) /api/v1/quests      (Quest-Liste)                │
//  │  3. Antwort wird geparst + in ApiQuest-Objekte gewandelt│
//  │  4. Fehler werden sauber zurückgegeben                  │
//  └─────────────────────────────────────────────────────────┘
//
//  ✏️  WAS DU ANPASSEN MUSST (wenn die API sich ändert):
//    → _endpoints Liste in fetchQuests()
//    → _parseResponse() wenn sich die JSON-Struktur ändert
//    → Bei einem neuen API-Key: nur _apiKey ändern
//
//  ── WO WIRD DIESE KLASSE AUFGERUFEN? ─────────────────────
//    lib/services/quest_manager.dart → load() → _refreshFromApi()
//
//  ── DEBUGGING ─────────────────────────────────────────────
//    setze _debugMode = true für JSON-Ausgabe im Log
//    Android Studio → Logcat → Filter: "OrbitQuestAPI"
//
// ══════════════════════════════════════════════════════════════

class FortniteQuestApiService {

  // ── Konfiguration ──────────────────────────────────────────
  //
  //  ✏️  HIER DEINEN API-KEY EINTRAGEN (einmal, fertig):
  //
  static const String _apiKey =
      '6cc5760588143c03d7df36cf43b68bc8186eaf144a77f82eff20206eb4b5a47d';

  static const String _baseUrl = 'https://prod.api-fortnite.com';

  /// Timeout pro Request (nicht zu kurz — API kann langsam sein)
  static const Duration _timeout = Duration(seconds: 25);

  /// true → gibt die rohe API-Antwort im Debug-Log aus
  /// Aktiviere dies wenn die Quests nicht geladen werden!
  static const bool _debugMode = true;

  // ── Singleton ─────────────────────────────────────────────
  static final FortniteQuestApiService instance =
      FortniteQuestApiService._();
  FortniteQuestApiService._();

  // ──────────────────────────────────────────────────────────
  //
  //  📡 HAUPT-METHODE: Quests laden
  //
  //  Probiert 3 Endpunkte automatisch nacheinander durch.
  //  Bei Erfolg wird die Antwort geparst und zurückgegeben.
  //  Beim Fehlschlagen aller Endpunkte: QuestApiResponse.error()
  //
  // ──────────────────────────────────────────────────────────

  Future<QuestApiResponse> fetchQuests({String language = 'en'}) async {

    // ── Endpunkte die nacheinander probiert werden ─────────
    //
    // ✏️  REIHENFOLGE ANPASSEN wenn ein bestimmter Endpunkt
    //     bevorzugt werden soll. Erster erfolgreicher gewinnt.
    //
    final endpoints = [
      // Endpunkt 1: Aktuelle Season-Challenges (allgemein)
      _buildUri('/api/v2/challenges', language: language),

      // Endpunkt 2: Ältere Version
      _buildUri('/api/v1/challenges', language: language),

      // Endpunkt 3: Quests-Endpunkt (generell, ohne accountId)
      _buildUri('/api/v1/quests', language: language),

      // Endpunkt 4: Player-Quests ohne Account (manche APIs
      //             geben allgemeine Daten zurück wenn kein
      //             accountId angegeben wird)
      _buildUri('/api/v3/quests', language: language),
    ];

    String lastError = 'Kein Endpunkt erreichbar';

    for (final uri in endpoints) {
      try {
        dev.log('🔍 Versuche: $uri', name: 'OrbitQuestAPI');

        final response = await http
            .get(uri, headers: _buildHeaders())
            .timeout(_timeout);

        dev.log('📥 HTTP ${response.statusCode} von $uri',
            name: 'OrbitQuestAPI');

        if (_debugMode) {
          // Ersten 500 Zeichen der Antwort ausgeben
          final preview = response.body.length > 500
              ? '${response.body.substring(0, 500)}...'
              : response.body;
          dev.log('📄 Antwort-Preview:\n$preview', name: 'OrbitQuestAPI');
        }

        if (response.statusCode == 200) {
          final result = _parseResponse(response.body, language: language);
          if (result.success && result.quests.isNotEmpty) {
            dev.log(
                '✅ ${result.quests.length} Quests geladen von $uri',
                name: 'OrbitQuestAPI');
            return result;
          }
          // 200 aber keine Quests → nächsten Endpunkt versuchen
          lastError = result.error ?? 'Keine Quests in Antwort';
          dev.log('⚠️  Keine Quests gefunden: $lastError',
              name: 'OrbitQuestAPI');

        } else if (response.statusCode == 401 || response.statusCode == 403) {
          // Auth-Fehler → kein Sinn, andere Endpunkte zu versuchen
          lastError = 'API-Key ungültig (HTTP ${response.statusCode}).\n'
              'Prüfe: fortnite_quest_api_service.dart → _apiKey';
          dev.log('❌ Auth-Fehler: $lastError', name: 'OrbitQuestAPI');
          break;

        } else {
          lastError = 'HTTP ${response.statusCode} von $uri';
          dev.log('⚠️  $lastError', name: 'OrbitQuestAPI');
        }

      } on Exception catch (e) {
        lastError = e.toString();
        dev.log('❌ Exception bei $uri: $e', name: 'OrbitQuestAPI');
      }
    }

    dev.log('❌ Alle Endpunkte fehlgeschlagen. Letzter Fehler: $lastError',
        name: 'OrbitQuestAPI');
    return QuestApiResponse.error(lastError);
  }

  // ──────────────────────────────────────────────────────────
  //  URI bauen
  // ──────────────────────────────────────────────────────────

  Uri _buildUri(String path, {String language = 'en'}) {
    // Sprache für die API formatieren
    // api-fortnite.com nutzt oft 'en-US' / 'de-DE' Format
    final langCode = language == 'de' ? 'de-DE' : 'en-US';

    return Uri.parse('$_baseUrl$path').replace(
      queryParameters: {
        'language': langCode,
        // Manche Endpunkte brauchen 'lang' statt 'language'
        'lang': language,
        // Aktuelle Season anfordern
        'season': 'current',
      },
    );
  }

  // ──────────────────────────────────────────────────────────
  //
  //  🔑 HTTP HEADERS
  //
  //  api-fortnite.com akzeptiert den API-Key in diesen Formen.
  //  Alle drei werden gesetzt — der Server nimmt was er kennt.
  //
  // ──────────────────────────────────────────────────────────

  Map<String, String> _buildHeaders() {
    return {
      // Standard Bearer Token (häufigste Form)
      'Authorization': 'Bearer $_apiKey',
      // Alternative: direkter API-Key Header
      'X-Api-Key': _apiKey,
      // Weitere übliche Varianten
      'api-key': _apiKey,

      'Accept':       'application/json',
      'Content-Type': 'application/json',
      'User-Agent':   'Orbit-App/0.3.1',
    };
  }

  // ──────────────────────────────────────────────────────────
  //
  //  🔍 JSON-PARSING
  //
  //  Diese Funktion versteht mehrere verschiedene JSON-Strukturen
  //  gleichzeitig. Egal wie die API antwortet — wir fangen es ab.
  //
  //  ✏️  DEBUGGING wenn Quests nicht erscheinen:
  //    1. _debugMode = true setzen
  //    2. App starten → Aufträge öffnen
  //    3. In Android Studio Logcat nach "OrbitQuestAPI" filtern
  //    4. Die "📄 Antwort-Preview" zeigt die echte API-Struktur
  //    5. Hier anpassen falls nötig
  //
  //  Unterstützte JSON-Strukturen:
  //
  //  STRUKTUR A: Flache Liste unter bekanntem Key
  //  { "result": true, "challenges": [ {...}, {...} ] }
  //  { "result": true, "quests": [ {...}, {...} ] }
  //  { "data": [ {...}, {...} ] }
  //
  //  STRUKTUR B: Nach Typ gruppiert
  //  { "weekly": [...], "daily": [...], "battlePass": [...] }
  //
  //  STRUKTUR C: Nach Modus gruppiert
  //  { "br": [...], "og": [...], "reload": [...] }
  //
  //  STRUKTUR D: Direkt als Array
  //  [ { "id": "...", "title": "...", ... }, ... ]
  //
  // ──────────────────────────────────────────────────────────

  QuestApiResponse _parseResponse(
    String body, {
    String language = 'en',
  }) {
    try {
      final decoded = jsonDecode(body);

      // ── STRUKTUR D: Direkt als JSON-Array ─────────────────
      if (decoded is List) {
        return _parseQuestList(
            decoded.whereType<Map<String, dynamic>>().toList(), language);
      }

      if (decoded is! Map<String, dynamic>) {
        return QuestApiResponse.error('Unerwartetes JSON-Format: ${decoded.runtimeType}');
      }

      final json = decoded;

      // Erfolg prüfen (API kann verschiedene Statusfelder haben)
      final rawSuccess = json['result'] ?? json['success'] ??
                         json['ok'] ?? json['status'];
      if (rawSuccess == false || rawSuccess == 'error') {
        final msg = json['error']   as String? ??
                    json['message'] as String? ??
                    'API meldet Fehler';
        return QuestApiResponse.error(msg);
      }

      // ── STRUKTUR A: Flache Liste ───────────────────────────
      for (final key in ['challenges', 'quests', 'data', 'items',
                         'bundle', 'results']) {
        final raw = json[key];
        if (raw is List && raw.isNotEmpty) {
          dev.log('📦 Struktur A: Key="$key" mit ${raw.length} Einträgen',
              name: 'OrbitQuestAPI');
          return _parseQuestList(
              raw.whereType<Map<String, dynamic>>().toList(), language);
        }
      }

      // ── STRUKTUR B: Nach Quest-Typ gruppiert ───────────────
      const typeKeys = [
        'weekly', 'daily', 'battlePass', 'story', 'milestone',
        'punchcard', 'seasonal', 'limited', 'event',
        'weekly_challenges', 'daily_challenges',
      ];
      final combinedB = <Map<String, dynamic>>[];
      for (final key in typeKeys) {
        final raw = json[key];
        if (raw is List) {
          for (final item in raw) {
            if (item is Map<String, dynamic>) {
              // Section-Feld aus dem Gruppenkey ableiten falls fehlt
              final withSection = Map<String, dynamic>.from(item);
              withSection.putIfAbsent('section', () => _sectionFromKey(key));
              combinedB.add(withSection);
            }
          }
        }
      }
      if (combinedB.isNotEmpty) {
        dev.log('📦 Struktur B: ${combinedB.length} Quests aus Typ-Gruppen',
            name: 'OrbitQuestAPI');
        return _parseQuestList(combinedB, language);
      }

      // ── STRUKTUR C: Nach Spielmodus gruppiert ──────────────
      const modeKeys = [
        'br', 'og', 'reload', 'lego', 'festival', 'blitz',
        'creative', 'reload', 'ballistic', 'delulu',
        'battle_royale', 'battleRoyale',
      ];
      final combinedC = <Map<String, dynamic>>[];
      for (final key in modeKeys) {
        final raw = json[key];
        if (raw is List) {
          for (final item in raw) {
            if (item is Map<String, dynamic>) {
              final withMode = Map<String, dynamic>.from(item);
              withMode.putIfAbsent('gameMode', () => key);
              combinedC.add(withMode);
            }
          }
        }
      }
      if (combinedC.isNotEmpty) {
        dev.log('📦 Struktur C: ${combinedC.length} Quests aus Modus-Gruppen',
            name: 'OrbitQuestAPI');
        return _parseQuestList(combinedC, language);
      }

      // ── Nichts gefunden: Debug-Info ausgeben ───────────────
      dev.log(
        '❓ Unbekannte JSON-Struktur. Vorhandene Keys: ${json.keys.join(', ')}\n'
        '   → Bitte in fortnite_quest_api_service.dart → '
        '_parseResponse() anpassen.',
        name: 'OrbitQuestAPI',
      );
      return QuestApiResponse.error(
        'Unbekannte API-Struktur.\n'
        'Keys: ${json.keys.join(", ")}\n'
        'Aktiviere _debugMode=true in fortnite_quest_api_service.dart '
        'und schaue ins Logcat.',
      );

    } on FormatException catch (e) {
      return QuestApiResponse.error('JSON-Parse-Fehler: $e');
    } catch (e) {
      return QuestApiResponse.error('Unerwarteter Fehler beim Parsen: $e');
    }
  }

  // ──────────────────────────────────────────────────────────
  //  Liste von Maps → Liste von ApiQuest-Objekten
  // ──────────────────────────────────────────────────────────

  QuestApiResponse _parseQuestList(
    List<Map<String, dynamic>> rawList,
    String language,
  ) {
    final quests = rawList
        .map((q) => ApiQuest.fromApiJson(q, language))
        .where((q) => q.id.isNotEmpty || q.title.isNotEmpty)
        .toList();

    dev.log('✅ ${quests.length} Quests erfolgreich geparst',
        name: 'OrbitQuestAPI');

    if (quests.isEmpty) {
      return QuestApiResponse.error('API hat geantwortet, aber keine Quests gefunden.');
    }

    return QuestApiResponse(success: true, quests: quests);
  }

  // ──────────────────────────────────────────────────────────
  //  Hilfsfunktion: API-Key aus Quest-Typ ableiten
  // ──────────────────────────────────────────────────────────

  String _sectionFromKey(String key) {
    const labels = {
      'weekly':             'Wöchentlich',
      'weekly_challenges':  'Wöchentlich',
      'daily':              'Täglich',
      'daily_challenges':   'Täglich',
      'battlePass':         'Battle Pass',
      'story':              'Story',
      'milestone':          'Meilensteine',
      'punchcard':          'Stempelkarte',
      'seasonal':           'Saisonal',
      'limited':            'Begrenzt',
      'event':              'Event',
    };
    return labels[key] ?? key;
  }
}
