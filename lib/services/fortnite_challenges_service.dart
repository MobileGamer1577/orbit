import 'dart:convert';
import 'package:http/http.dart' as http;

// ══════════════════════════════════════════════════════════════
//
//  🌐 FORTNITE CHALLENGES SERVICE
//  Datei: lib/services/fortnite_challenges_service.dart
//
//  Lädt aktuelle Fortnite Quests von fortnite-api.com.
//  Kein API-Key erforderlich.
//
//  Endpunkt:
//    GET https://fortnite-api.com/v2/challenges?language=de
//
//  Datenstruktur (vereinfacht):
//    data.bundles[] → jedes Bundle = eine Woche / Gruppe
//      bundle.quests[] → einzelne Aufträge
//
// ══════════════════════════════════════════════════════════════

// ── API-URL ────────────────────────────────────────────────────
const String _kChallengesUrl =
    'https://fortnite-api.com/v2/challenges?language=de';

const Duration _kTimeout = Duration(seconds: 20);

// ──────────────────────────────────────────────────────────────
//  Datenmodelle
// ──────────────────────────────────────────────────────────────

/// Ein einzelner Fortnite Auftrag
class FnQuest {
  final String id;
  final String name;        // Auftragsname
  final String description; // z.B. "0/5 Eliminierungen"
  final int    xp;          // XP-Belohnung

  const FnQuest({
    required this.id,
    required this.name,
    required this.description,
    required this.xp,
  });

  // ──────────────────────────────────────────────────────────
  //  fromJson — robuster Parser
  //
  //  Die API verwendet für Name/Beschreibung verschiedene Keys:
  //    name / title / quest_name
  //    description / objective / desc
  //  Alle Varianten werden abgefangen.
  // ──────────────────────────────────────────────────────────
  factory FnQuest.fromJson(Map<String, dynamic> j) {
    // Name: verschiedene mögliche Keys ausprobieren
    final name = _str(j['name'])        .isNotEmpty ? _str(j['name'])
               : _str(j['title'])       .isNotEmpty ? _str(j['title'])
               : _str(j['quest_name'])  .isNotEmpty ? _str(j['quest_name'])
               : '(Unbekannter Auftrag)';

    // Beschreibung
    final desc = _str(j['description']) .isNotEmpty ? _str(j['description'])
               : _str(j['objective'])   .isNotEmpty ? _str(j['objective'])
               : '';

    // XP: Int oder String
    final xp = _parseInt(j['xp'] ?? j['reward_xp'] ?? j['rewardXp'] ?? 0);

    return FnQuest(
      id:          _str(j['id'] ?? j['questId'] ?? ''),
      name:        name,
      description: desc,
      xp:          xp,
    );
  }
}

/// Eine Gruppe von Aufträgen (z.B. "Woche 1", "Tägliche Aufträge")
class FnBundle {
  final String        label;   // z.B. "Woche 1"
  final List<FnQuest> quests;

  const FnBundle({required this.label, required this.quests});
}

// ──────────────────────────────────────────────────────────────
//  Service
// ──────────────────────────────────────────────────────────────

class FortniteChallengessService {
  // Privater Konstruktor — nur statische Methoden
  FortniteChallengessService._();

  // ────────────────────────────────────────────────────────────
  //  fetchBundles()
  //
  //  Lädt alle aktuellen Aufträge und gruppiert sie in Bundles.
  //  Gibt eine leere Liste zurück wenn die API nicht erreichbar ist.
  //
  //  Verwendung:
  //    final bundles = await FortniteChallengessService.fetchBundles();
  // ────────────────────────────────────────────────────────────
  static Future<List<FnBundle>> fetchBundles() async {
    final res = await http
        .get(
          Uri.parse(_kChallengesUrl),
          headers: {
            'Accept':     'application/json',
            'User-Agent': 'Orbit-App',
          },
        )
        .timeout(_kTimeout);

    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}: ${res.reasonPhrase}');
    }

    final decoded = jsonDecode(res.body);
    return _parse(decoded);
  }

  // ────────────────────────────────────────────────────────────
  //  _parse — Robuster Parser
  //
  //  Die API kann verschiedene Strukturen zurückgeben.
  //  Dieser Parser versucht alle bekannten Formate:
  //
  //  Format A: { "data": { "bundles": [...] } }
  //  Format B: { "data": { "weekly": [...], "daily": [...] } }
  //  Format C: { "data": [...] }  — flache Liste
  //  Format D: [...]              — direkte Liste
  // ────────────────────────────────────────────────────────────
  static List<FnBundle> _parse(dynamic decoded) {
    final bundles = <FnBundle>[];

    // Ober-Ebene: "data" extrahieren falls vorhanden
    dynamic data = decoded;
    if (decoded is Map && decoded.containsKey('data')) {
      data = decoded['data'];
    }

    // ── Format A: data.bundles ─────────────────────────────
    if (data is Map && data['bundles'] is List) {
      for (final b in data['bundles'] as List) {
        final bundle = _parseBundle(b);
        if (bundle != null && bundle.quests.isNotEmpty) {
          bundles.add(bundle);
        }
      }
      return bundles;
    }

    // ── Format B: data.weekly / data.daily / data.seasonal ──
    final typeKeys = ['weekly', 'daily', 'seasonal', 'battlePass',
                      'milestone', 'story', 'event', 'limited'];
    bool foundAny = false;
    if (data is Map) {
      for (final key in typeKeys) {
        if (data[key] is List) {
          final label = _bundleLabel(key);
          for (final b in data[key] as List) {
            final bundle = _parseBundle(b, fallbackLabel: label);
            if (bundle != null && bundle.quests.isNotEmpty) {
              bundles.add(bundle);
              foundAny = true;
            }
          }
        }
      }
      if (foundAny) return bundles;

      // ── Format B2: data enthält direkt quests ─────────────
      if (data['quests'] is List) {
        final quests = _parseQuestList(data['quests'] as List);
        if (quests.isNotEmpty) {
          return [FnBundle(label: 'Aufträge', quests: quests)];
        }
      }
    }

    // ── Format C/D: flache Liste ────────────────────────────
    if (data is List) {
      final List<dynamic> list = data;

      // Handelt es sich um eine Liste von Bundles oder Quests?
      if (list.isNotEmpty && list.first is Map) {
        final first = list.first as Map;
        // Hat ein Bundle-artiges Element 'quests' oder 'challenges'?
        if (first.containsKey('quests') || first.containsKey('challenges')) {
          for (final b in list) {
            final bundle = _parseBundle(b);
            if (bundle != null && bundle.quests.isNotEmpty) {
              bundles.add(bundle);
            }
          }
          return bundles;
        }
        // Sonst: direkte Quest-Liste
        final quests = _parseQuestList(list);
        if (quests.isNotEmpty) {
          return [FnBundle(label: 'Aufträge', quests: quests)];
        }
      }
    }

    return bundles;
  }

  /// Parst ein einzelnes Bundle-Objekt
  static FnBundle? _parseBundle(
    dynamic raw, {
    String fallbackLabel = 'Aufträge',
  }) {
    if (raw is! Map) return null;
    final j = raw as Map<String, dynamic>;

    // Label
    final label = _str(j['name']  ?? j['title'] ?? j['label']
                     ?? j['week'] ?? j['id']    ?? fallbackLabel);

    // Quests können unter verschiedenen Keys liegen
    List<dynamic> rawQuests = [];
    for (final key in ['quests', 'challenges', 'items']) {
      if (j[key] is List) {
        rawQuests = j[key] as List;
        break;
      }
    }

    final quests = _parseQuestList(rawQuests);
    return FnBundle(label: label.isEmpty ? fallbackLabel : label, quests: quests);
  }

  /// Parst eine Liste von Quest-Objekten
  static List<FnQuest> _parseQuestList(List<dynamic> raw) {
    return raw
        .whereType<Map<String, dynamic>>()
        .map(FnQuest.fromJson)
        .where((q) => q.name.isNotEmpty)
        .toList();
  }

  /// Übersetzt API-interne Keys in lesbare deutsche Labels
  static String _bundleLabel(String key) {
    const labels = {
      'weekly':     'Wöchentlich',
      'daily':      'Täglich',
      'seasonal':   'Saisonal',
      'battlePass': 'Battle Pass',
      'milestone':  'Meilensteine',
      'story':      'Story',
      'event':      'Event',
      'limited':    'Begrenzt',
    };
    return labels[key] ?? key;
  }
}

// ── Hilfsfunktionen ───────────────────────────────────────────

String _str(dynamic v) => v?.toString() ?? '';

int _parseInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is double) return v.toInt();
  return int.tryParse(v.toString()) ?? 0;
}
