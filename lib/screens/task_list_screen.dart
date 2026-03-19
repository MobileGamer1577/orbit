import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../l10n/app_localizations.dart';
import '../storage/task_store.dart';
import '../theme/orbit_theme.dart';
import '../widgets/orbit_glass_card.dart';

// ──────────────────────────────────────────────────────────────
// Datenmodelle
// ──────────────────────────────────────────────────────────────

class _QuestItem {
  final String id;
  final String title;
  final String description;
  const _QuestItem({required this.id, required this.title, required this.description});
}

/// Normale Phase (Starthilfe, Wochenaufträge etc.)
class _NormalPhase {
  final String label;
  final List<_QuestItem> quests;
  const _NormalPhase({required this.label, required this.quests});
}

/// Meilenstein-Phase: enthält alle 20 Unter-Phasen
class _MilestonePhase {
  final String label;
  /// Index 0 = Phase 1, Index 19 = Phase 20
  final List<List<_QuestItem>> subPhases;
  const _MilestonePhase({required this.label, required this.subPhases});

  /// Die erste Phase deren Aufträge NICHT alle erledigt sind
  int get activeSubPhaseIndex {
    for (int i = 0; i < subPhases.length; i++) {
      final quests = subPhases[i];
      if (quests.isEmpty) continue; // leere Phase überspringen
      final allDone = quests.every((q) => TaskStore.isDone(q.id));
      if (!allDone) return i;
    }
    // Alle done → letzte Phase mit Inhalt zeigen
    for (int i = subPhases.length - 1; i >= 0; i--) {
      if (subPhases[i].isNotEmpty) return i;
    }
    return 0;
  }

  int get totalSubPhases => subPhases.length;

  /// Alle Aufträge aus allen Unterphasen (für Gesamtfortschritt)
  List<_QuestItem> get allQuests =>
      subPhases.expand((q) => q).toList();
}

// Ein Eintrag in der gerenderten Liste ist entweder normal oder milestone
sealed class _Section {}
class _NormalSection extends _Section {
  final _NormalPhase phase;
  _NormalSection(this.phase);
}
class _MilestoneSection extends _Section {
  final _MilestonePhase phase;
  _MilestoneSection(this.phase);
}

// ──────────────────────────────────────────────────────────────
// Screen
// ──────────────────────────────────────────────────────────────

class TaskListScreen extends StatefulWidget {
  final String title;
  final String jsonAssetPath;

  const TaskListScreen({
    super.key,
    required this.title,
    required this.jsonAssetPath,
  });

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  List<_Section> _sections = [];
  bool           _loading  = true;
  bool           _empty    = false;
  String         _query    = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() => _query = _searchCtrl.text));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loading) _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Laden ──────────────────────────────────────────────────

  Future<void> _load() async {
    final path = widget.jsonAssetPath.trim();
    if (path.isEmpty) {
      if (mounted) setState(() { _loading = false; _empty = true; });
      return;
    }

    try {
      final lang = Localizations.localeOf(context).languageCode;

      final results = await Future.wait([
        rootBundle.loadString(path),
        rootBundle.loadString('assets/data/quests_database.json'),
      ]);

      final modeData = jsonDecode(results[0]) as Map<String, dynamic>;
      final db       = jsonDecode(results[1]) as Map<String, dynamic>;

      _QuestItem questFromDb(String id) {
        final entry = db[id];
        if (entry == null) return _QuestItem(id: id, title: id, description: '');
        final langData = (entry[lang] ?? entry['de']) as Map<String, dynamic>;
        return _QuestItem(
          id:          id,
          title:       (langData['title']       as String?) ?? id,
          description: (langData['description'] as String?) ?? '',
        );
      }

      // Neues Format mit "phases" Array
      if (modeData.containsKey('phases')) {
        final rawPhases = modeData['phases'] as List;

        if (rawPhases.isEmpty) {
          if (mounted) setState(() { _loading = false; _empty = true; });
          return;
        }

        final sections = <_Section>[];

        for (final p in rawPhases) {
          final type = (p['type'] as String?) ?? 'normal';

          if (type == 'milestone') {
            // ── Meilenstein-Sektion ───────────────────────
            final labelMap = p['label'];
            final String label = labelMap is Map
                ? ((labelMap[lang] ?? labelMap['de'] ?? '') as String)
                : labelMap?.toString() ?? '';

            final rawMilestones = p['milestone_phases'] as List;
            final subPhases = rawMilestones.map((mp) {
              final questIds = (mp['quests'] as List).cast<String>();
              return questIds.map(questFromDb).toList();
            }).toList();

            sections.add(_MilestoneSection(
              _MilestonePhase(label: label, subPhases: subPhases),
            ));

          } else {
            // ── Normale Sektion ───────────────────────────
            final labelMap = p['label'];
            final String label = labelMap is Map
                ? ((labelMap[lang] ?? labelMap['de'] ?? '') as String)
                : labelMap?.toString() ?? '';

            final questIds = (p['quests'] as List).cast<String>();
            final quests   = questIds.map(questFromDb).toList();

            if (quests.isNotEmpty) {
              sections.add(_NormalSection(
                _NormalPhase(label: label, quests: quests),
              ));
            }
          }
        }

        if (sections.isEmpty) {
          if (mounted) setState(() { _loading = false; _empty = true; });
          return;
        }

        if (mounted) setState(() { _sections = sections; _loading = false; });

      } else {
        // Altes Fallback-Format { "tasks": [...] }
        final tasks  = (modeData['tasks'] as List?)?.cast<Map>() ?? [];
        final quests = tasks.map((t) => _QuestItem(
          id:          (t['id'] as String?) ?? '',
          title:       (t['title'] as String?) ?? '',
          description: (t['description'] as String?) ?? '',
        )).toList();

        if (mounted) setState(() {
          _sections = [_NormalSection(_NormalPhase(label: '', quests: quests))];
          _loading  = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() { _loading = false; _empty = true; });
    }
  }

  // ── Statistik ──────────────────────────────────────────────

  int get _totalQuests => _sections.fold(0, (sum, s) => switch (s) {
    _NormalSection    n => sum + n.phase.quests.length,
    _MilestoneSection m => sum + m.phase.allQuests.length,
  });

  int get _doneQuests => _sections.fold(0, (sum, s) {
    final quests = switch (s) {
      _NormalSection    n => n.phase.quests,
      _MilestoneSection m => m.phase.allQuests,
    };
    return sum + quests.where((q) => TaskStore.isDone(q.id)).length;
  });

  // ── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF10041E),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF7C4DFF))),
      );
    }

    if (_empty || _sections.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: OrbitBackground(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Header(title: widget.title),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: OrbitGlassCard(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Icon(Icons.hourglass_top_rounded,
                              color: Colors.white.withOpacity(0.70)),
                          const SizedBox(width: 12),
                          Text(l10n.taskComingSoon,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              )),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final total    = _totalQuests;
    final done     = _doneQuests;
    final progress = total == 0 ? 0.0 : done / total;

    // Für die Suchfunktion: alle sichtbaren Aufträge zählen
    final q = _query.trim().toLowerCase();
    int visibleCount = 0;
    for (final s in _sections) {
      switch (s) {
        case _NormalSection n:
          visibleCount += q.isEmpty
              ? n.phase.quests.length
              : n.phase.quests.where((quest) =>
                  quest.title.toLowerCase().contains(q) ||
                  quest.description.toLowerCase().contains(q)).length;
        case _MilestoneSection m:
          final activeQuests = m.phase.subPhases[m.phase.activeSubPhaseIndex];
          visibleCount += q.isEmpty
              ? activeQuests.length
              : activeQuests.where((quest) =>
                  quest.title.toLowerCase().contains(q) ||
                  quest.description.toLowerCase().contains(q)).length;
      }
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: OrbitBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ───────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: _Header(title: widget.title),
              ),

              // ── Fortschritt + Suche ───────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 7,
                              backgroundColor: Colors.white.withOpacity(0.12),
                              valueColor: const AlwaysStoppedAnimation(
                                  Color(0xFF9C6FFF)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text('$done / $total',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.75),
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            )),
                      ],
                    ),
                    const SizedBox(height: 12),

                    OrbitGlassCard(
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 4),
                        child: Row(
                          children: [
                            Icon(Icons.search,
                                color: Colors.white.withOpacity(0.55), size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _searchCtrl,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500),
                                decoration: InputDecoration(
                                  hintText: l10n.taskSearchHint,
                                  hintStyle: TextStyle(
                                      color: Colors.white.withOpacity(0.40),
                                      fontSize: 15),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            if (_query.isNotEmpty)
                              GestureDetector(
                                onTap: () {
                                  _searchCtrl.clear();
                                  setState(() => _query = '');
                                },
                                child: Icon(Icons.close,
                                    color: Colors.white.withOpacity(0.45),
                                    size: 18),
                              ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 6),
                    Text(l10n.taskQuestCount(visibleCount),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.38),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                        )),
                  ],
                ),
              ),

              // ── Sections-Liste ────────────────────────────
              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: _sections.length,
                  itemBuilder: (context, i) {
                    final section = _sections[i];
                    return switch (section) {
                      _NormalSection    n => _NormalSectionWidget(
                          phase:   n.phase,
                          query:   _query,
                          onToggle: _toggle,
                        ),
                      _MilestoneSection m => _MilestoneSectionWidget(
                          phase:   m.phase,
                          query:   _query,
                          onToggle: _toggle,
                        ),
                    };
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggle(String id, bool current) async {
    await TaskStore.setDone(id, !current);
    if (mounted) setState(() {});
  }
}

// ──────────────────────────────────────────────────────────────
// Normale Sektion
// ──────────────────────────────────────────────────────────────

class _NormalSectionWidget extends StatelessWidget {
  final _NormalPhase phase;
  final String query;
  final Future<void> Function(String, bool) onToggle;

  const _NormalSectionWidget({
    required this.phase,
    required this.query,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final q = query.trim().toLowerCase();
    final visible = q.isEmpty
        ? phase.quests
        : phase.quests.where((quest) =>
            quest.title.toLowerCase().contains(q) ||
            quest.description.toLowerCase().contains(q)).toList();

    if (visible.isEmpty) return const SizedBox.shrink();

    final done  = phase.quests.where((q) => TaskStore.isDone(q.id)).length;
    final total = phase.quests.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (phase.label.isNotEmpty) ...[
          const SizedBox(height: 20),
          _PhaseHeader(label: phase.label, done: done, total: total),
          const SizedBox(height: 10),
        ] else
          const SizedBox(height: 8),

        ...visible.asMap().entries.map((entry) {
          final quest = entry.value;
          final isDone = TaskStore.isDone(quest.id);
          return Padding(
            padding: EdgeInsets.only(
                bottom: entry.key < visible.length - 1 ? 10 : 0),
            child: _TaskCard(
              title:    quest.title,
              desc:     quest.description,
              done:     isDone,
              onToggle: () => onToggle(quest.id, isDone),
            ),
          );
        }),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Meilenstein-Sektion — zeigt immer nur aktive Phase
// ──────────────────────────────────────────────────────────────

class _MilestoneSectionWidget extends StatelessWidget {
  final _MilestonePhase phase;
  final String query;
  final Future<void> Function(String, bool) onToggle;

  const _MilestoneSectionWidget({
    required this.phase,
    required this.query,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final activeIndex  = phase.activeSubPhaseIndex;
    final activeQuests = phase.subPhases[activeIndex];
    final totalPhases  = phase.totalSubPhases;

    // Gesamtfortschritt über alle Phasen
    final allQuests = phase.allQuests;
    final doneAll   = allQuests.where((q) => TaskStore.isDone(q.id)).length;
    final totalAll  = allQuests.length;

    final q = query.trim().toLowerCase();
    final visible = q.isEmpty
        ? activeQuests
        : activeQuests.where((quest) =>
            quest.title.toLowerCase().contains(q) ||
            quest.description.toLowerCase().contains(q)).toList();

    // Aktive Phase komplett abgehakt?
    final activeAllDone = activeQuests.isNotEmpty &&
        activeQuests.every((quest) => TaskStore.isDone(quest.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),

        // ── Meilenstein-Header ────────────────────────────
        Row(
          children: [
            // Badge mit Label
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD600).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFFFD600).withOpacity(0.40),
                  ),
                ),
                child: Text(
                  phase.label.toUpperCase(),
                  style: TextStyle(
                    color: const Color(0xFFFFD600).withOpacity(0.90),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: totalAll == 0 ? 0 : doneAll / totalAll,
                  minHeight: 4,
                  backgroundColor: Colors.white.withOpacity(0.08),
                  valueColor:
                      const AlwaysStoppedAnimation(Color(0xFFFFD600)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$doneAll/$totalAll',
              style: TextStyle(
                color: Colors.white.withOpacity(0.40),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // ── Phase X/20 Indikator ──────────────────────────
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: activeAllDone
                    ? const Color(0xFF00E676).withOpacity(0.15)
                    : Colors.white.withOpacity(0.07),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: activeAllDone
                      ? const Color(0xFF00E676).withOpacity(0.50)
                      : Colors.white.withOpacity(0.15),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    activeAllDone ? Icons.check_circle : Icons.flag_rounded,
                    size: 13,
                    color: activeAllDone
                        ? const Color(0xFF00E676)
                        : Colors.white.withOpacity(0.55),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Phase ${activeIndex + 1} / $totalPhases',
                    style: TextStyle(
                      color: activeAllDone
                          ? const Color(0xFF00E676)
                          : Colors.white.withOpacity(0.65),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            if (activeAllDone && activeIndex < totalPhases - 1) ...[
              const SizedBox(width: 8),
              Text(
                '→ Phase ${activeIndex + 2} freigeschaltet!',
                style: TextStyle(
                  color: const Color(0xFF00E676).withOpacity(0.80),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),

        const SizedBox(height: 10),

        // ── Aufträge der aktiven Phase ────────────────────
        if (activeQuests.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 8),
            child: OrbitGlassCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.lock_outline,
                      color: Colors.white.withOpacity(0.35), size: 18),
                  const SizedBox(width: 10),
                  Text(
                    'Noch keine Aufträge für diese Phase.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.40),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...visible.asMap().entries.map((entry) {
            final quest  = entry.value;
            final isDone = TaskStore.isDone(quest.id);
            return Padding(
              padding: EdgeInsets.only(
                  bottom: entry.key < visible.length - 1 ? 10 : 0),
              child: _TaskCard(
                title:    quest.title,
                desc:     quest.description,
                done:     isDone,
                onToggle: () => onToggle(quest.id, isDone),
              ),
            );
          }),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Phasen-Header (für normale Sektionen)
// ──────────────────────────────────────────────────────────────

class _PhaseHeader extends StatelessWidget {
  final String label;
  final int done;
  final int total;

  const _PhaseHeader({
    required this.label,
    required this.done,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
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
            label.toUpperCase(),
            style: TextStyle(
              color: const Color(0xFF9C6FFF).withOpacity(0.90),
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : done / total,
              minHeight: 4,
              backgroundColor: Colors.white.withOpacity(0.08),
              valueColor:
                  const AlwaysStoppedAnimation(Color(0xFF9C6FFF)),
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
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Header
// ──────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final String title;
  const _Header({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back,
              color: Colors.white.withOpacity(0.90)),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            title,
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
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Auftrags-Karte
// ──────────────────────────────────────────────────────────────

class _TaskCard extends StatelessWidget {
  final String title;
  final String desc;
  final bool done;
  final VoidCallback onToggle;

  const _TaskCard({
    required this.title,
    required this.desc,
    required this.done,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return OrbitGlassCard(
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: onToggle,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  width: 26,
                  height: 26,
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
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
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
                    if (desc.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        desc,
                        style: TextStyle(
                          color: Colors.white
                              .withOpacity(done ? 0.30 : 0.55),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          height: 1.35,
                        ),
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
