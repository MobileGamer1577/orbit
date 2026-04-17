import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/api_quest.dart';
import '../services/quest_manager.dart';
import '../theme/orbit_theme.dart';
import '../widgets/orbit_glass_card.dart';

// ══════════════════════════════════════════════════════════════
//
//  📋 API QUEST LIST SCREEN
//  Datei: lib/screens/api_quest_list_screen.dart
//
//  Zeigt Quests an, die von der api-fortnite.com API kommen.
//  Ersetzt TaskListScreen für Fortnite-Modi.
//
//  Features:
//    ✅ XP-Fortschrittsanzeige (verdient / gesamt)
//    ✅ Quest-Anzahl (1/10)
//    ✅ Meilenstein-Aufträge mit Phasen
//    ✅ Suchfunktion
//    ✅ Offline-Support (gecachte Daten)
//    ✅ Hintergrund-Refresh
//
// ══════════════════════════════════════════════════════════════

class ApiQuestListScreen extends StatefulWidget {
  /// Spieltitel für die AppBar
  final String title;

  /// Orbit Spiel-ID (z.B. 'fortnite')
  final String gameId;

  /// Orbit Modus-ID (z.B. 'fortnite_br', 'fortnite_og')
  final String modeId;

  const ApiQuestListScreen({
    super.key,
    required this.title,
    required this.gameId,
    required this.modeId,
  });

  @override
  State<ApiQuestListScreen> createState() => _ApiQuestListScreenState();
}

class _ApiQuestListScreenState extends State<ApiQuestListScreen> {
  late QuestManager _manager;
  String _query = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _manager = QuestManager(
      gameId:   widget.gameId,
      modeId:   widget.modeId,
      language: 'de', // ← wird in didChangeDependencies gesetzt
    );
    _searchCtrl.addListener(() => setState(() => _query = _searchCtrl.text));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Sprache aus dem Kontext lesen (de/en)
    final lang = Localizations.localeOf(context).languageCode;
    _manager = QuestManager(
      gameId:   widget.gameId,
      modeId:   widget.modeId,
      language: lang,
    );
    _manager.addListener(_onManagerUpdate);
    _manager.load();
  }

  void _onManagerUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _manager.removeListener(_onManagerUpdate);
    _manager.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ──────────────────────────────────────────────────────────
  //  Suchfilter auf Sections anwenden
  // ──────────────────────────────────────────────────────────

  List<QuestSection> _filteredSections() {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _manager.sections;

    return _manager.sections.map((section) {
      final visible = section.quests.where((quest) =>
        quest.title.toLowerCase().contains(q) ||
        quest.description.toLowerCase().contains(q),
      ).toList();
      if (visible.isEmpty) return null;
      return QuestSection(
        label:       section.label,
        isMilestone: section.isMilestone,
        quests:      visible,
      );
    }).whereType<QuestSection>().toList();
  }

  // ──────────────────────────────────────────────────────────
  //  Build
  // ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sections = _filteredSections();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: OrbitBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Header ─────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.arrow_back,
                        color: Colors.white.withOpacity(0.90),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    // Manueller Refresh-Button
                    if (_manager.state != QuestLoadState.loading)
                      IconButton(
                        icon: _manager.isRefreshing
                            ? const SizedBox(
                                width: 18, height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white54))
                            : Icon(
                                Icons.refresh,
                                color: Colors.white.withOpacity(0.70),
                              ),
                        onPressed: () => _manager.forceRefresh(),
                      ),
                  ],
                ),
              ),

              // ── XP + Quest Fortschrittsanzeige ────────────
              if (_manager.hasData) ...[
                _ProgressHeader(manager: _manager),
              ],

              // ── Suchfeld ──────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: OrbitGlassCard(
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    child: Row(
                      children: [
                        Icon(Icons.search, color: Colors.white.withOpacity(0.55), size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _searchCtrl,
                            style: const TextStyle(color: Colors.white, fontSize: 15),
                            decoration: InputDecoration(
                              hintText: l10n.taskSearchHint,
                              hintStyle: TextStyle(
                                color: Colors.white.withOpacity(0.40),
                                fontSize: 15,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                        if (_query.isNotEmpty)
                          GestureDetector(
                            onTap: () { _searchCtrl.clear(); setState(() => _query = ''); },
                            child: Icon(Icons.close,
                                color: Colors.white.withOpacity(0.45), size: 18),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Anzahl sichtbarer Quests ──────────────────
              if (_manager.hasData)
                Padding(
                  padding: const EdgeInsets.only(left: 20, bottom: 4, top: 2),
                  child: Text(
                    l10n.taskQuestCount(
                      sections.fold(0, (s, sec) => s + sec.quests.length)),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.38),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

              // ── Haupt-Inhalt ───────────────────────────────
              Expanded(child: _buildBody(sections, l10n)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(List<QuestSection> sections, AppLocalizations l10n) {
    switch (_manager.state) {
      case QuestLoadState.idle:
      case QuestLoadState.loading:
        return const Center(
          child: CircularProgressIndicator(color: Color(0xFF9C6FFF)),
        );

      case QuestLoadState.error:
        return _ErrorWidget(
          message: _manager.errorMessage ?? 'Fehler',
          onRetry: () => _manager.forceRefresh(),
        );

      case QuestLoadState.loaded:
      case QuestLoadState.refreshing:
        if (!_manager.hasData) {
          return Center(
            child: Text(
              l10n.taskComingSoon,
              style: TextStyle(color: Colors.white.withOpacity(0.45)),
            ),
          );
        }
        if (sections.isEmpty) {
          return Center(
            child: Text(
              l10n.noResults,
              style: TextStyle(color: Colors.white.withOpacity(0.45)),
            ),
          );
        }
        return _QuestList(sections: sections, manager: _manager);
    }
  }
}


// ══════════════════════════════════════════════════════════════
//  FORTSCHRITTS-HEADER (XP + Quest-Anzahl)
// ══════════════════════════════════════════════════════════════

class _ProgressHeader extends StatelessWidget {
  final QuestManager manager;
  const _ProgressHeader({required this.manager});

  String _fmtXp(int xp) {
    if (xp >= 1000000) return '${(xp / 1000000).toStringAsFixed(1)}M';
    if (xp >= 1000)    return '${(xp / 1000).toStringAsFixed(0)}k';
    return '$xp';
  }

  @override
  Widget build(BuildContext context) {
    final earned = manager.earnedXp;
    final total  = manager.totalXp;
    final done   = manager.doneQuestCount;
    final count  = manager.totalQuestCount;
    final progress = total == 0 ? 0.0 : earned / total;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: OrbitGlassCard(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          children: [
            Row(
              children: [
                // Quest-Anzahl
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.checklist,
                        size: 18,
                        color: const Color(0xFF9C6FFF).withOpacity(0.80),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$done / $count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Aufträge',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.55),
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                // XP
                Row(
                  children: [
                    Icon(
                      Icons.bolt,
                      size: 18,
                      color: const Color(0xFFFFD600).withOpacity(0.90),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_fmtXp(earned)} / ${_fmtXp(total)} XP',
                      style: const TextStyle(
                        color: Color(0xFFFFD600),
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 7,
                backgroundColor: Colors.white.withOpacity(0.12),
                valueColor: const AlwaysStoppedAnimation(Color(0xFF9C6FFF)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ══════════════════════════════════════════════════════════════
//  QUEST-LISTE MIT SECTIONS
// ══════════════════════════════════════════════════════════════

class _QuestList extends StatelessWidget {
  final List<QuestSection> sections;
  final QuestManager manager;

  const _QuestList({required this.sections, required this.manager});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      itemCount: sections.length,
      itemBuilder: (context, i) {
        final section = sections[i];
        return _SectionWidget(section: section, manager: manager);
      },
    );
  }
}


// ══════════════════════════════════════════════════════════════
//  SEKTION (z.B. "Woche 1")
// ══════════════════════════════════════════════════════════════

class _SectionWidget extends StatelessWidget {
  final QuestSection section;
  final QuestManager manager;

  const _SectionWidget({required this.section, required this.manager});

  @override
  Widget build(BuildContext context) {
    // Fortschritt dieser Section
    int done = 0, total = 0;
    for (final q in section.quests) {
      if (q.isMilestone) {
        total += q.stages.length.clamp(1, 999);
        done  += q.stages.where(
          (s) => manager.isStageChecked(q.id, s.stage),
        ).length;
      } else {
        total++;
        if (manager.isChecked(q.id)) done++;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 18),

        // ── Sektion-Header ────────────────────────────────
        Row(
          children: [
            // Label
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF7C4DFF).withOpacity(0.20),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF9C6FFF).withOpacity(0.40),
                ),
              ),
              child: Text(
                section.label.toUpperCase(),
                style: TextStyle(
                  color: const Color(0xFF9C6FFF).withOpacity(0.90),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Fortschrittsbalken
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: total == 0 ? 0 : done / total,
                  minHeight: 4,
                  backgroundColor: Colors.white.withOpacity(0.08),
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF9C6FFF)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$done/$total',
              style: TextStyle(
                color: Colors.white.withOpacity(0.40),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // ── Quests ────────────────────────────────────────
        ...section.quests.asMap().entries.map((entry) {
          final q = entry.value;
          final last = entry.key == section.quests.length - 1;

          return Padding(
            padding: EdgeInsets.only(bottom: last ? 0 : 10),
            child: q.isMilestone
                ? _MilestoneCard(quest: q, manager: manager)
                : _NormalCard(quest: q, manager: manager),
          );
        }),
      ],
    );
  }
}


// ══════════════════════════════════════════════════════════════
//  NORMALE QUEST-KARTE
// ══════════════════════════════════════════════════════════════

class _NormalCard extends StatelessWidget {
  final ApiQuest quest;
  final QuestManager manager;

  const _NormalCard({required this.quest, required this.manager});

  @override
  Widget build(BuildContext context) {
    final done = manager.isChecked(quest.id);

    return OrbitGlassCard(
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => manager.setChecked(quest.id, !done),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Checkbox
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                width: 26, height: 26,
                margin: const EdgeInsets.only(top: 1),
                decoration: BoxDecoration(
                  color: done
                      ? const Color(0xFF7C4DFF).withOpacity(0.85)
                      : Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: done
                        ? const Color(0xFF9C6FFF)
                        : Colors.white.withOpacity(0.22),
                    width: 1.5,
                  ),
                ),
                child: done
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 14),

              // Titel + Beschreibung
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quest.title,
                      style: TextStyle(
                        color: done
                            ? Colors.white.withOpacity(0.45)
                            : Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        decoration: done
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        decorationColor: Colors.white.withOpacity(0.35),
                      ),
                    ),
                    if (quest.description.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        quest.description,
                        style: TextStyle(
                          color: Colors.white.withOpacity(
                              done ? 0.30 : 0.55),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          height: 1.35,
                        ),
                      ),
                    ],
                    if (quest.xp > 0) ...[
                      const SizedBox(height: 5),
                      _XpBadge(xp: quest.xp, earned: done),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// ══════════════════════════════════════════════════════════════
//  MEILENSTEIN-AUFTRAGS-KARTE (mit Phasen)
// ══════════════════════════════════════════════════════════════

class _MilestoneCard extends StatelessWidget {
  final ApiQuest quest;
  final QuestManager manager;

  const _MilestoneCard({required this.quest, required this.manager});

  @override
  Widget build(BuildContext context) {
    // Aktive Phase = erste nicht abgehakte
    int activeStageIdx = quest.stages.indexWhere(
      (s) => !manager.isStageChecked(quest.id, s.stage),
    );
    if (activeStageIdx == -1) activeStageIdx = quest.stages.length - 1;

    final bool allDone = activeStageIdx == quest.stages.length - 1 &&
        manager.isStageChecked(quest.id, quest.stages.last.stage);

    // Falls keine Stages → als normale Quest behandeln
    if (quest.stages.isEmpty) {
      final done = manager.isChecked(quest.id);
      return OrbitGlassCard(
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => manager.setChecked(quest.id, !done),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            child: Row(
              children: [
                // Checkbox
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 26, height: 26,
                  decoration: BoxDecoration(
                    color: done
                        ? const Color(0xFFFFD600).withOpacity(0.80)
                        : Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: done
                          ? const Color(0xFFFFD600)
                          : Colors.white.withOpacity(0.22),
                      width: 1.5,
                    ),
                  ),
                  child: done
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quest.title,
                        style: TextStyle(
                          color: done
                              ? Colors.white.withOpacity(0.45)
                              : Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          decoration: done
                              ? TextDecoration.lineThrough
                              : null,
                          decorationColor:
                              Colors.white.withOpacity(0.35),
                        ),
                      ),
                      if (quest.xp > 0) ...[
                        const SizedBox(height: 5),
                        _XpBadge(xp: quest.xp, earned: done),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final activeStage = quest.stages[activeStageIdx];
    final isDone = manager.isStageChecked(quest.id, activeStage.stage);
    final phaseColor = allDone
        ? const Color(0xFF00E676)
        : const Color(0xFFFFD600);

    return OrbitGlassCard(
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => manager.setStageChecked(
          quest.id, activeStage.stage, !isDone),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Milestone-Checkbox
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 26, height: 26,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  color: isDone
                      ? const Color(0xFFFFD600).withOpacity(0.80)
                      : Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDone
                        ? const Color(0xFFFFD600)
                        : Colors.white.withOpacity(0.22),
                    width: 1.5,
                  ),
                ),
                child: isDone
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Phase-Badge
                    Container(
                      margin: const EdgeInsets.only(bottom: 5),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: phaseColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: phaseColor.withOpacity(0.45)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            allDone
                                ? Icons.check_circle
                                : Icons.flag_rounded,
                            size: 10, color: phaseColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Phase ${activeStage.stage} / ${quest.stages.length}',
                            style: TextStyle(
                              color: phaseColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Quest-Titel
                    Text(
                      quest.title,
                      style: TextStyle(
                        color: isDone
                            ? Colors.white.withOpacity(0.45)
                            : Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        decoration: isDone
                            ? TextDecoration.lineThrough
                            : null,
                        decorationColor:
                            Colors.white.withOpacity(0.35),
                      ),
                    ),

                    // Aktive Phase Beschreibung
                    if (activeStage.description.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        activeStage.description,
                        style: TextStyle(
                          color: Colors.white.withOpacity(
                              isDone ? 0.30 : 0.55),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          height: 1.35,
                        ),
                      ),
                    ],

                    if (quest.xp > 0) ...[
                      const SizedBox(height: 5),
                      _XpBadge(
                        xp: quest.xp,
                        earned: allDone,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// ══════════════════════════════════════════════════════════════
//  XP-BADGE
// ══════════════════════════════════════════════════════════════

class _XpBadge extends StatelessWidget {
  final int  xp;
  final bool earned;

  const _XpBadge({required this.xp, required this.earned});

  String _fmtXp(int xp) {
    if (xp >= 1000000) return '${(xp / 1000000).toStringAsFixed(1)}M';
    if (xp >= 1000)    return '${(xp / 1000).toStringAsFixed(0)}k';
    return '$xp';
  }

  @override
  Widget build(BuildContext context) {
    final color = earned
        ? const Color(0xFF00E676)
        : const Color(0xFFFFD600);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.bolt, size: 13, color: color),
        const SizedBox(width: 3),
        Text(
          '${_fmtXp(xp)} XP',
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}


// ══════════════════════════════════════════════════════════════
//  FEHLER-WIDGET
// ══════════════════════════════════════════════════════════════

class _ErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorWidget({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              color: Colors.white.withOpacity(0.25),
              size: 52,
            ),
            const SizedBox(height: 16),
            Text(
              'Quests konnten nicht geladen werden',
              style: TextStyle(
                color: Colors.white.withOpacity(0.75),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                color: Colors.white.withOpacity(0.40),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Hinweis für Entwickler
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16, top: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B35).withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFF6B35).withOpacity(0.35),
                ),
              ),
              child: Text(
                '🛠 Tipp: Öffne fortnite_quest_api_service.dart '
                'und passe _buildUrl() sowie _parseResponse() '
                'an die echte API-Struktur an.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.65),
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),

            FilledButton.icon(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF7C4DFF),
              ),
              icon: const Icon(Icons.refresh),
              label: const Text('Erneut versuchen'),
            ),
          ],
        ),
      ),
    );
  }
}
