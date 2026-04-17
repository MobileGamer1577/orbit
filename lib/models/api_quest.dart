import 'dart:convert';

// ══════════════════════════════════════════════════════════════
//
//  📦 API QUEST MODEL
//  Datei: lib/models/api_quest.dart
//
//  Dieses Modell bildet die Datenstruktur der api-fortnite.com
//  Quest/Challenge-API ab.
//
//  ✏️  FALLS DIE API ANDERE FELDER LIEFERT:
//    → Nur fromJson() anpassen, nirgendwo sonst!
//    → Alle anderen Dateien bleiben unverändert.
//
//  Struktur einer typischen API-Antwort:
//  {
//    "result": true,
//    "quests": [
//      {
//        "id": "quest_br_w1_001",
//        "title": { "en": "...", "de": "..." },
//        "description": { "en": "...", "de": "..." },
//        "xp": 15000,
//        "gameMode": "br",         ← Spielmodus (br, og, reload, ...)
//        "section": "Woche 1",     ← Gruppierung (Woche, Meilensteine, ...)
//        "isMilestone": false,     ← true = Meilenstein-Quest mit Phasen
//        "stages": [               ← Phasen eines Meilenstein-Auftrags
//          {
//            "stage": 1,
//            "description": { "en": "...", "de": "..." },
//            "count": 100
//          }
//        ]
//      }
//    ]
//  }
//
// ══════════════════════════════════════════════════════════════


// ──────────────────────────────────────────────────────────────
//  Eine einzelne Quest-Phase (für Meilenstein-Aufträge)
// ──────────────────────────────────────────────────────────────

class ApiQuestStage {
  /// Nummer der Phase (1-basiert)
  final int stage;

  /// Übersetzter Text der Phase
  final String description;

  /// Zielwert (z.B. "Eliminiere 0/100 Spieler")
  final int count;

  const ApiQuestStage({
    required this.stage,
    required this.description,
    required this.count,
  });

  // ── JSON Serialisierung (für Hive-Cache) ──────────────────

  Map<String, dynamic> toJson() => {
    'stage': stage,
    'description': description,
    'count': count,
  };

  factory ApiQuestStage.fromJson(Map<String, dynamic> j) {
    return ApiQuestStage(
      stage:       (j['stage']       as int?)    ?? 1,
      description: (j['description'] as String?) ?? '',
      count:       (j['count']       as int?)    ?? 0,
    );
  }

  // ── API-Parser ────────────────────────────────────────────
  //
  // ✏️  HIER ANPASSEN falls die API die Phasen anders aufbaut.
  //    Wichtig: `lang` ist 'de' oder 'en'.
  //
  factory ApiQuestStage.fromApiJson(Map<String, dynamic> j, String lang) {
    // Mehrsprachiger Text: zuerst gewählte Sprache, dann Englisch als Fallback
    String _text(dynamic raw) {
      if (raw == null) return '';
      if (raw is String) return raw;
      if (raw is Map) {
        return (raw[lang] as String?)
            ?? (raw['en'] as String?)
            ?? (raw['de'] as String?)
            ?? raw.values.whereType<String>().firstOrNull
            ?? '';
      }
      return raw.toString();
    }

    return ApiQuestStage(
      stage:       (j['stage'] as int?)    ?? 1,
      description: _text(j['description']),
      count:       (j['count'] as int?)    ?? 0,
    );
  }
}


// ──────────────────────────────────────────────────────────────
//  Eine einzelne Quest / Auftrag
// ──────────────────────────────────────────────────────────────

class ApiQuest {
  /// Eindeutige ID (aus der API)
  final String id;

  /// Angezeigter Titel
  final String title;

  /// Beschreibung (optional)
  final String description;

  /// XP-Belohnung (z.B. 15000)
  final int xp;

  /// Spielmodus-Identifier aus der API
  /// Beispiele: 'br', 'og', 'reload', 'lego', 'festival', 'blitz', 'kreativ'
  final String gameMode;

  /// Sektion/Gruppe (z.B. "Woche 1", "Meilensteine", "Story")
  final String section;

  /// true = Meilenstein-Quest mit mehreren Phasen
  final bool isMilestone;

  /// Phasen eines Meilenstein-Auftrags (leer wenn !isMilestone)
  final List<ApiQuestStage> stages;

  const ApiQuest({
    required this.id,
    required this.title,
    required this.description,
    required this.xp,
    required this.gameMode,
    required this.section,
    required this.isMilestone,
    required this.stages,
  });

  // ──────────────────────────────────────────────────────────
  //  Hive-Cache Serialisierung
  // ──────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
    'id':          id,
    'title':       title,
    'description': description,
    'xp':          xp,
    'gameMode':    gameMode,
    'section':     section,
    'isMilestone': isMilestone,
    'stages':      stages.map((s) => s.toJson()).toList(),
  };

  factory ApiQuest.fromJson(Map<String, dynamic> j) {
    return ApiQuest(
      id:          (j['id']          as String?) ?? '',
      title:       (j['title']       as String?) ?? '',
      description: (j['description'] as String?) ?? '',
      xp:          (j['xp']          as int?)    ?? 0,
      gameMode:    (j['gameMode']    as String?) ?? '',
      section:     (j['section']     as String?) ?? '',
      isMilestone: (j['isMilestone'] as bool?)   ?? false,
      stages: ((j['stages'] as List?) ?? [])
          .whereType<Map<String, dynamic>>()
          .map(ApiQuestStage.fromJson)
          .toList(),
    );
  }

  // ──────────────────────────────────────────────────────────
  //
  //  🔥 API-Parser — HIER DIE ECHTE API-STRUKTUR EINTRAGEN
  //
  //  Diese Methode übersetzt die API-Antwort in unser Modell.
  //  Sie wird NUR in fortnite_quest_api_service.dart aufgerufen.
  //
  //  ✏️  ANPASSEN wenn die API andere Feldnamen hat:
  //    z.B.: j['challenge_name'] statt j['title']
  //
  //  Mehrsprachigkeit:
  //    Die API liefert entweder:
  //      a) Direkt einen String: "title": "Eliminiere Spieler"
  //      b) Ein Objekt:         "title": { "en": "...", "de": "..." }
  //    Beide Fälle werden automatisch behandelt.
  //
  // ──────────────────────────────────────────────────────────

  factory ApiQuest.fromApiJson(Map<String, dynamic> j, String lang) {

    // ── Hilfsfunktion: Mehrsprachiger Text ──────────────────
    String _text(dynamic raw) {
      if (raw == null) return '';
      if (raw is String) return raw;
      if (raw is Map) {
        return (raw[lang] as String?)
            ?? (raw['en'] as String?)
            ?? (raw['de'] as String?)
            ?? raw.values.whereType<String>().firstOrNull
            ?? '';
      }
      return raw.toString();
    }

    // ── XP: direkt als int oder als String ("15000") ────────
    int _xp(dynamic raw) {
      if (raw == null) return 0;
      if (raw is int) return raw;
      return int.tryParse(raw.toString()) ?? 0;
    }

    // ── Phasen parsen ────────────────────────────────────────
    final rawStages = j['stages'] as List?;
    final stages = rawStages
        ?.whereType<Map<String, dynamic>>()
        .map((s) => ApiQuestStage.fromApiJson(s, lang))
        .toList() ?? [];

    // ── Ist es ein Meilenstein-Auftrag? ─────────────────────
    //    Erkennungsmerkmale: hat stages ODER explizites Flag
    final bool isMilestone = (j['isMilestone'] as bool?) ??
        (j['is_milestone'] as bool?) ??
        (stages.length > 1);

    // ✏️  SPIELMODUS: Hier den richtigen API-Feldnamen eintragen
    //    Mögliche Namen: 'gameMode', 'game_mode', 'mode', 'playlist'
    final String gameMode =
        (j['gameMode'] as String?) ??
        (j['game_mode'] as String?) ??
        (j['mode'] as String?) ??
        (j['playlist'] as String?) ??
        '';

    // ✏️  SEKTION: Hier den richtigen API-Feldnamen eintragen
    //    Mögliche Namen: 'section', 'week', 'bundle', 'category'
    final String section =
        (j['section'] as String?) ??
        (j['week'] != null ? 'Woche ${j['week']}' : null) ??
        (j['bundle'] as String?) ??
        (j['category'] as String?) ??
        '';

    // ✏️  TITEL + BESCHREIBUNG: ggf. andere Feldnamen
    final String title =
        _text(j['title']) .isNotEmpty ? _text(j['title']) :
        _text(j['name'])  .isNotEmpty ? _text(j['name'])  :
        _text(j['quest_name']) ;

    final String description =
        _text(j['description']).isNotEmpty ? _text(j['description']) :
        _text(j['objective'])  .isNotEmpty ? _text(j['objective'])   :
        '';

    return ApiQuest(
      id:          (j['id'] as String?) ?? (j['questId'] as String?) ?? '',
      title:       title,
      description: description,
      xp:          _xp(j['xp'] ?? j['reward_xp'] ?? j['rewardXp']),
      gameMode:    gameMode,
      section:     section,
      isMilestone: isMilestone,
      stages:      stages,
    );
  }
}


// ──────────────────────────────────────────────────────────────
//  QuestApiResponse — vollständige API-Antwort
// ──────────────────────────────────────────────────────────────

class QuestApiResponse {
  final bool success;
  final List<ApiQuest> quests;
  final String? error;

  const QuestApiResponse({
    required this.success,
    required this.quests,
    this.error,
  });

  factory QuestApiResponse.error(String message) =>
      QuestApiResponse(success: false, quests: [], error: message);

  // ── JSON Serialisierung (für Cache) ─────────────────────
  String toJsonString() => jsonEncode({
    'success': success,
    'quests': quests.map((q) => q.toJson()).toList(),
  });

  factory QuestApiResponse.fromJsonString(String jsonStr) {
    final j = jsonDecode(jsonStr) as Map<String, dynamic>;
    return QuestApiResponse(
      success: (j['success'] as bool?) ?? true,
      quests: ((j['quests'] as List?) ?? [])
          .whereType<Map<String, dynamic>>()
          .map(ApiQuest.fromJson)
          .toList(),
    );
  }
}
