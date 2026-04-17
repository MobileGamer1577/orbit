import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'dart:developer' as dev;
import '../models/api_quest.dart';
import '../services/fortnite_quest_api_service.dart';
import '../storage/quest_cache_store.dart';

// ══════════════════════════════════════════════════════════════
//
//  🎮 QUEST MANAGER  —  VOLLSTÄNDIGE IMPLEMENTIERUNG
//  Datei: lib/services/quest_manager.dart
//
//  Zuständig für:
//    ✅ Cache laden → sofort in der UI anzeigen
//    ✅ API im Hintergrund anfragen (frische Daten)
//    ✅ Quests nach Orbit-Modus filtern
//    ✅ Quests in Sections gruppieren
//    ✅ XP-Fortschritt berechnen
//    ✅ Checkbox-State in Hive speichern
//
//  ── ABLAUF BEIM SCREEN-ÖFFNEN ────────────────────────────
//
//  game_select_screen → mode_select_screen
//    → ApiQuestListScreen(gameId, modeId)
//      → QuestManager(gameId, modeId, language)
//        1. load() aufgerufen
//        2. Hive-Cache laden → sofort in UI angezeigt
//        3. Hintergrund: API anfragen (wenn Cache > 1h alt)
//        4. Bei neuen Daten: notifyListeners() → UI updated
//
// ══════════════════════════════════════════════════════════════


// ──────────────────────────────────────────────────────────────
//  Lade-Zustände des Managers
// ──────────────────────────────────────────────────────────────

enum QuestLoadState {
  idle,        // Noch nicht gestartet
  loading,     // Erstladen (kein Cache vorhanden)
  refreshing,  // Cache aktiv, API läuft im Hintergrund
  loaded,      // Daten verfügbar ✅
  error,       // Fehler, keine Daten vorhanden
}


// ──────────────────────────────────────────────────────────────
//  QuestSection — eine Gruppe von Quests in der UI
//  Beispiele: "Woche 1", "Meilensteine", "Story"
// ──────────────────────────────────────────────────────────────

class QuestSection {
  final String label;
  final bool isMilestone;
  final List<ApiQuest> quests;

  const QuestSection({
    required this.label,
    required this.isMilestone,
    required this.quests,
  });
}


// ──────────────────────────────────────────────────────────────
//  QuestManager
// ──────────────────────────────────────────────────────────────

class QuestManager extends ChangeNotifier {

  // ── Konfiguration ─────────────────────────────────────────
  final String gameId;    // 'fortnite', 'bo7', ...
  final String modeId;    // 'fortnite_br', 'fortnite_og', ...
  final String language;  // 'de' oder 'en'

  QuestManager({
    required this.gameId,
    required this.modeId,
    required this.language,
  });

  // ── State ─────────────────────────────────────────────────
  QuestLoadState     _state        = QuestLoadState.idle;
  List<QuestSection> _sections     = [];
  String?            _errorMessage;
  DateTime?          _lastUpdated;

  QuestLoadState     get state        => _state;
  List<QuestSection> get sections     => _sections;
  String?            get errorMessage => _errorMessage;
  DateTime?          get lastUpdated  => _lastUpdated;
  bool               get isLoading    => _state == QuestLoadState.loading;
  bool               get isRefreshing => _state == QuestLoadState.refreshing;
  bool               get hasData      => _sections.isNotEmpty;

  // ──────────────────────────────────────────────────────────
  //  Quests laden (Cache → API)
  // ──────────────────────────────────────────────────────────

  Future<void> load() async {
    if (_state == QuestLoadState.loading) return;

    // Schritt 1: Cache sofort laden → UI erscheint ohne Wartezeit
    final cached = QuestCacheStore.load(gameId);
    if (cached != null && cached.quests.isNotEmpty) {
      _applyData(cached.quests);
      _lastUpdated = QuestCacheStore.lastUpdated(gameId);
      _state = QuestLoadState.refreshing;
      notifyListeners();

      // Schritt 2: API nur anfragen wenn Cache veraltet (> 1 Stunde)
      if (!QuestCacheStore.isValid(gameId)) {
        await _refreshFromApi(silent: true);
      } else {
        _state = QuestLoadState.loaded;
        notifyListeners();
      }
    } else {
      // Kein Cache → Ladescreen anzeigen + direkt API anfragen
      _state = QuestLoadState.loading;
      notifyListeners();
      await _refreshFromApi(silent: false);
    }
  }

  /// Manueller Refresh (z.B. Refresh-Button oben rechts)
  Future<void> forceRefresh() async {
    await QuestCacheStore.clear(gameId);
    await _refreshFromApi(silent: hasData);
  }

  Future<void> _refreshFromApi({required bool silent}) async {
    if (!silent) {
      _state = QuestLoadState.loading;
      notifyListeners();
    }

    dev.log(
      '🔄 API-Refresh: gameId=$gameId modeId=$modeId lang=$language',
      name: 'OrbitQuestManager',
    );

    final result = await FortniteQuestApiService.instance
        .fetchQuests(language: language);

    if (result.success && result.quests.isNotEmpty) {
      await QuestCacheStore.save(gameId, result);
      _lastUpdated  = DateTime.now();
      _errorMessage = null;
      _applyData(result.quests);
      _state = QuestLoadState.loaded;
      dev.log(
        '✅ Geladen: ${result.quests.length} Quests gesamt, '
        '${_sections.length} Sections für modeId=$modeId',
        name: 'OrbitQuestManager',
      );
    } else {
      _errorMessage = result.error;
      _state = hasData ? QuestLoadState.loaded : QuestLoadState.error;
      dev.log('❌ API-Fehler: ${result.error}', name: 'OrbitQuestManager');
    }

    notifyListeners();
  }

  // ──────────────────────────────────────────────────────────
  //
  //  🗺️  MODUS-MAPPING
  //
  //  Übersetzt Orbit-Modus-IDs (aus game_registry.dart) in
  //  gameMode-Werte die die API liefert.
  //
  //  ✏️  ANPASSEN wenn du die echten API-Werte kennst:
  //    1. App starten + Aufträge öffnen
  //    2. In Android Studio Logcat nach "OrbitQuestAPI" filtern
  //    3. "📄 Antwort-Preview" zeigt die echte API-Antwort
  //    4. Schaue nach dem "gameMode"-Feld in den Quest-Objekten
  //    5. Diesen Wert rechts in die passende Liste eintragen
  //
  //  Beispiel: API liefert { "gameMode": "weekly_br", ... }
  //  → 'fortnite_br': ['weekly_br', ...]  ← hier eintragen
  //
  // ──────────────────────────────────────────────────────────

  static const Map<String, List<String>> _modeMapping = {

    // ── BATTLE ROYALE ─────────────────────────────────────
    'fortnite_br': [
      'br', 'battleRoyale', 'battle_royale', 'BattleRoyale',
      'battle royale', 'weekly', 'default', 'main',
      'br_quests', 'battle_pass',
    ],

    // ── OG ───────────────────────────────────────────────
    'fortnite_og': [
      'og', 'OG', 'og_br', 'classic', 'oldschool', 'original',
      'og_fortnite', 'fortnite_og', 'og_quests',
    ],

    // ── RELOAD ───────────────────────────────────────────
    'fortnite_reload': [
      'reload', 'Reload', 'RELOAD', 'reload_br',
      'fortnite_reload', 'reload_royale', 'reload_quests',
    ],

    // ── LEGO FORTNITE ─────────────────────────────────────
    'fortnite_lego': [
      'lego', 'LEGO', 'lego_fortnite', 'LegoFortnite',
      'lego_br', 'lego_survival', 'lego_quests',
    ],

    // ── FESTIVAL ─────────────────────────────────────────
    'fortnite_festival': [
      'festival', 'Festival', 'FESTIVAL', 'music', 'jam',
      'jam_stage', 'jamstage', 'fortnite_festival', 'festival_quests',
    ],

    // ── BLITZ ROYALE ─────────────────────────────────────
    'fortnite_blitz_royale': [
      'blitz', 'blitzRoyale', 'blitz_royale', 'BlitzRoyale',
      'BLITZ', 'blitz_br', 'blitz_quests',
    ],

    // ── KREATIV ───────────────────────────────────────────
    'fortnite_kreativ': [
      'creative', 'Creative', 'CREATIVE', 'kreativ', 'Kreativ',
      'creative_mode', 'fortnite_creative', 'creative_quests',
    ],

    // ── BALLISTIC ─────────────────────────────────────────
    'fortnite_ballistic': [
      'ballistic', 'Ballistic', 'BALLISTIC',
      'tactical', 'counter', 'ballistic_quests',
    ],

    // ── DELULU ────────────────────────────────────────────
    'fortnite_delulu': [
      'delulu', 'Delulu', 'DELULU', 'team_royale', 'delulu_quests',
    ],
  };

  // ──────────────────────────────────────────────────────────
  //  Quests nach Modus filtern + in Sections gruppieren
  // ──────────────────────────────────────────────────────────

  void _applyData(List<ApiQuest> allQuests) {
    final apiModes = _modeMapping[modeId] ?? [_extractRawMode(modeId)];
    final hasGameMode = allQuests.any((q) => q.gameMode.isNotEmpty);

    List<ApiQuest> filtered;

    if (hasGameMode) {
      filtered = allQuests.where((q) {
        if (q.gameMode.isEmpty) return true;
        return apiModes.any(
          (m) => q.gameMode.toLowerCase() == m.toLowerCase(),
        );
      }).toList();

      dev.log(
        '🔍 Mode-Filter: ${allQuests.length} → ${filtered.length} '
        '(modeId=$modeId)',
        name: 'OrbitQuestManager',
      );
    } else {
      // API liefert kein gameMode-Feld → alle Quests anzeigen
      filtered = allQuests;
      dev.log(
        'ℹ️  Kein gameMode in API-Antwort → alle ${allQuests.length} '
        'Quests ungefiltert angezeigt',
        name: 'OrbitQuestManager',
      );
    }

    // Nach Section gruppieren
    final bySection = <String, List<ApiQuest>>{};
    for (final q in filtered) {
      final key = q.section.isNotEmpty ? q.section : _defaultSection;
      bySection.putIfAbsent(key, () => []).add(q);
    }

    // Sections erstellen
    _sections = bySection.entries.map((e) => QuestSection(
      label:       e.key,
      isMilestone: e.value.any((q) => q.isMilestone),
      quests:      e.value,
    )).toList();

    // Sortieren: Woche 1, Woche 2, ... → dann Rest alphabetisch
    _sections.sort((a, b) {
      final aNum = _extractNumber(a.label);
      final bNum = _extractNumber(b.label);
      if (aNum != null && bNum != null) return aNum.compareTo(bNum);
      if (aNum != null) return -1;
      if (bNum != null) return 1;
      return a.label.compareTo(b.label);
    });

    if (_state != QuestLoadState.refreshing) {
      _state = QuestLoadState.loaded;
    }
  }

  String get _defaultSection => language == 'de' ? 'Aufträge' : 'Quests';

  String _extractRawMode(String orbitId) =>
      orbitId.replaceFirst('fortnite_', '').replaceFirst('bo7_', '');

  int? _extractNumber(String label) {
    final m = RegExp(r'\d+').firstMatch(label);
    return m != null ? int.tryParse(m.group(0)!) : null;
  }

  // ──────────────────────────────────────────────────────────
  //  XP-Fortschritt
  // ──────────────────────────────────────────────────────────

  int get totalQuestCount {
    int n = 0;
    for (final s in _sections) {
      for (final q in s.quests) {
        n += q.isMilestone ? q.stages.length.clamp(1, 999) : 1;
      }
    }
    return n;
  }

  int get doneQuestCount {
    int n = 0;
    for (final s in _sections) {
      for (final q in s.quests) {
        if (q.isMilestone) {
          n += q.stages.where((st) => _isStageChecked(q.id, st.stage)).length;
        } else {
          if (_isChecked(q.id)) n++;
        }
      }
    }
    return n;
  }

  int get totalXp => _sections.fold(
      0, (s, sec) => s + sec.quests.fold(0, (sq, q) => sq + q.xp));

  int get earnedXp {
    int xp = 0;
    for (final s in _sections) {
      for (final q in s.quests) {
        if (q.isMilestone) {
          final done =
              q.stages.where((st) => _isStageChecked(q.id, st.stage)).length;
          if (q.stages.isNotEmpty) {
            xp += (q.xp * done / q.stages.length).round();
          }
        } else {
          if (_isChecked(q.id)) xp += q.xp;
        }
      }
    }
    return xp;
  }

  // ──────────────────────────────────────────────────────────
  //  Checkbox-State in Hive
  //
  //  Schlüssel-Format in 'task_state' Box:
  //    Normale Quests:     'done:api:{questId}'
  //    Meilenstein-Phase:  'done:api:{questId}_s{stageNr}'
  // ──────────────────────────────────────────────────────────

  bool _isChecked(String questId) {
    try {
      return Hive.box('task_state')
          .get('done:api:$questId', defaultValue: false) as bool;
    } catch (_) {
      return false;
    }
  }

  bool _isStageChecked(String questId, int stage) {
    try {
      return Hive.box('task_state')
          .get('done:api:${questId}_s$stage', defaultValue: false) as bool;
    } catch (_) {
      return false;
    }
  }

  Future<void> setChecked(String questId, bool value) async {
    await Hive.box('task_state').put('done:api:$questId', value);
    notifyListeners();
  }

  Future<void> setStageChecked(
      String questId, int stage, bool value) async {
    await Hive.box('task_state')
        .put('done:api:${questId}_s$stage', value);
    notifyListeners();
  }

  bool isChecked(String questId) => _isChecked(questId);
  bool isStageChecked(String questId, int stage) =>
      _isStageChecked(questId, stage);
}
