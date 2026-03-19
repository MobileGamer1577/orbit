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

/// Normaler Auftrag (kein Meilenstein)
class _NormalPhase {
  final String label;
  final List<_QuestItem> quests;
  const _NormalPhase({required this.label, required this.quests});
}

/// Ein einzelner Meilenstein-Auftrag mit bis zu 20 Phasen.
/// Jede Phase ist ein eigener Quest-Eintrag in der DB.
/// Der Fortschritt ist unabhängig von anderen Meilenstein-Aufträgen.
class _MilestoneQuest {
  /// Alle Phasen dieses Auftrags (Index 0 = Phase 1, Index 19 = Phase 20)
  final List<_QuestItem> phases;

  const _MilestoneQuest({required this.phases});

  int get totalPhases => phases.length;

  /// Index der aktuell aktiven Phase (erste nicht abgehakte)
  int get activePhaseIndex {
    for (int i = 0; i < phases.length; i++) {
      if (!TaskStore.isDone(phases[i].id)) return i;
    }
    // Alle abgehakt → letzte Phase anzeigen
    return phases.length - 1;
  }

  _QuestItem get activePhase => phases[activePhaseIndex];

  bool get allDone => phases.every((p) => TaskStore.isDone(p.id));

  /// Fortschritt: Anzahl abgehakter Phasen
  int get doneCount => phases.where((p) => TaskStore.isDone(p.id)).length;
}

/// Eine Meilenstein-Sektion enthält mehrere unabhängige Meilenstein-Aufträge
class _MilestoneSection {
  final String label;
  final List<_MilestoneQuest> quests;
  const _MilestoneSection({required this.label, required this.quests});

  /// Gesamt-Phasen über alle Aufträge (für den Header-Fortschritt)
  int get totalPhases => quests.fold(0, (s, q) => s + q.totalPhases);
  int get donePhases  => quests.fold(0, (s, q) => s + q.doneCount);
}

// Polymorphe Sections-Liste
sealed class _Section {}
class _NormalSectionItem extends _Section {
  final _NormalPhase phase;
  _NormalSectionItem(this.phase);
}
class _MilestoneSectionItem extends _Section {
  final _MilestoneSection section;
  _MilestoneSectionItem(this.section);
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
  bool _loading = true;
  bool _empty   = false;
  String _query = '';
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
            // ── Meilenstein-Sektion ───────────────────────────────────
            // "quests" ist eine Liste von Objekten mit "phases"-Array
            final labelMap = p['label'];
            final String label = labelMap is Map
                ? ((labelMap[lang] ?? labelMap['de'] ?? '') as String)
                : labelMap?.toString() ?? '';

            final rawQuests = p['quests'] as List;
            final milestoneQuests = rawQuests.map((q) {
              final phaseIds = (q['phases'] as List).cast<String>();
              return _MilestoneQuest(
                phases: phaseIds.map(questFromDb).toList(),
              );
            }).toList();

            if (milestoneQuests.isNotEmpty) {
              sections.add(_MilestoneSectionItem(
                _MilestoneSection(label: label, quests: milestoneQuests),
              ));
            }

          } else {
            // ── Normale Sektion ───────────────────────────────────────
            final labelMap = p['label'];
            final String label = labelMap is Map
                ? ((labelMap[lang] ?? labelMap['de'] ?? '') as String)
                : labelMap?.toString() ?? '';

            final questIds = (p['quests'] as List).cast<String>();
            final quests   = questIds.map(questFromDb).toList();

            if (quests.isNotEmpty) {
              sections.add(_NormalSectionItem(
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
        // Altes Fallback-Format
        final tasks  = (modeData['tasks'] as List?)?.cast<Map>() ?? [];
        final quests = tasks.map((t) => _QuestItem(
          id:          (t['id'] as String?) ?? '',
          title:       (t['title'] as String?) ?? '',
          description: (t['description'] as String?) ?? '',
        )).toList();

        if (mounted) setState(() {
          _sections = [_NormalSectionItem(_NormalPhase(label: '', quests: quests))];
          _loading  = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() { _loading = false; _empty = true; });
    }
  }

  // ── Gesamtfortschritt ──────────────────────────────────────

  int get _totalQuests => _sections.fold(0, (sum, s) => switch (s) {
    _NormalSectionItem    n => sum + n.phase.quests.length,
    _MilestoneSectionItem m => sum + m.section.totalPhases,
  });

  int get _doneQuests => _sections.fold(0, (sum, s) => switch (s) {
    _NormalSectionItem    n => sum + n.phase.quests.where((q) => TaskStore.isDone(q.id)).length,
    _MilestoneSectionItem m => sum + m.section.donePhases,
  });

  // ── Sichtbare Aufträge zählen (für Suche) ─────────────────

  int _visibleCount() {
    final q = _query.trim().toLowerCase();
    int count = 0;
    for (final s in _sections) {
      switch (s) {
        case _NormalSectionItem n:
          count += q.isEmpty
              ? n.phase.quests.length
              : n.phase.quests.where((quest) =>
                  quest.title.toLowerCase().contains(q) ||
                  quest.description.toLowerCase().contains(q)).length;
        case _MilestoneSectionItem m:
          // Für Meilensteine: aktive Phase jedes Auftrags prüfen
          for (final mq in m.section.quests) {
            final active = mq.activePhase;
            if (q.isEmpty ||
                active.title.toLowerCase().contains(q) ||
                active.description.toLowerCase().contains(q)) {
              count++;
            }
          }
      }
    }
    return count;
  }

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

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: OrbitBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: _Header(title: widget.title),
              ),

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
                              valueColor: const AlwaysStoppedAnimation(Color(0xFF9C6FFF)),
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
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
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
                                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
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
                    Text(l10n.taskQuestCount(_visibleCount()),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.38),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                        )),
                  ],
                ),
              ),

              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: _sections.length,
                  itemBuilder: (context, i) {
                    final section = _sections[i];
                    return switch (section) {
                      _NormalSectionItem    n => _NormalSectionWidget(
                          phase: n.phase, query: _query, onToggle: _toggle),
                      _MilestoneSectionItem m => _MilestoneSectionWidget(
                          section: m.section, query: _query, onToggle: _toggle),
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
    required this.phase, required this.query, required this.onToggle,
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
          final quest  = entry.value;
          final isDone = TaskStore.isDone(quest.id);
          return Padding(
            padding: EdgeInsets.only(bottom: entry.key < visible.length - 1 ? 10 : 0),
            child: _TaskCard(
              title: quest.title, desc: quest.description,
              done: isDone, onToggle: () => onToggle(quest.id, isDone),
            ),
          );
        }),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Meilenstein-Sektion
// Alle Aufträge gleichzeitig sichtbar, jeder mit eigenem Phase-Badge
// ──────────────────────────────────────────────────────────────

class _MilestoneSectionWidget extends StatelessWidget {
  final _MilestoneSection section;
  final String query;
  final Future<void> Function(String, bool) onToggle;

  const _MilestoneSectionWidget({
    required this.section, required this.query, required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final q = query.trim().toLowerCase();

    // Aufträge filtern (nach aktiver Phase suchen)
    final visible = section.quests.where((mq) {
      if (q.isEmpty) return true;
      final active = mq.activePhase;
      return active.title.toLowerCase().contains(q) ||
             active.description.toLowerCase().contains(q);
    }).toList();

    if (visible.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),

        // ── Sektion-Header mit Gesamtfortschritt ──────────
        Row(
          children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD600).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFFD600).withOpacity(0.40)),
                ),
                child: Text(
                  section.label.toUpperCase(),
                  style: TextStyle(
                    color: const Color(0xFFFFD600).withOpacity(0.90),
                    fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: section.totalPhases == 0 ? 0 : section.donePhases / section.totalPhases,
                  minHeight: 4,
                  backgroundColor: Colors.white.withOpacity(0.08),
                  valueColor: const AlwaysStoppedAnimation(Color(0xFFFFD600)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${section.donePhases}/${section.totalPhases}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.40),
                fontSize: 11, fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // ── Alle Meilenstein-Aufträge ─────────────────────
        ...visible.asMap().entries.map((entry) {
          final mq     = entry.value;
          final active = mq.activePhase;
          final isDone = TaskStore.isDone(active.id);

          return Padding(
            padding: EdgeInsets.only(bottom: entry.key < visible.length - 1 ? 10 : 0),
            child: _MilestoneTaskCard(
              title:       active.title,
              desc:        active.description,
              done:        isDone,
              allDone:     mq.allDone,
              phaseIndex:  mq.activePhaseIndex,
              totalPhases: mq.totalPhases,
              onToggle:    () => onToggle(active.id, isDone),
            ),
          );
        }),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Meilenstein-Auftrags-Karte (mit Phase-Badge)
// ──────────────────────────────────────────────────────────────

class _MilestoneTaskCard extends StatelessWidget {
  final String title;
  final String desc;
  final bool   done;
  final bool   allDone;
  final int    phaseIndex;
  final int    totalPhases;
  final VoidCallback onToggle;

  const _MilestoneTaskCard({
    required this.title, required this.desc,
    required this.done, required this.allDone,
    required this.phaseIndex, required this.totalPhases,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final phaseColor = allDone
        ? const Color(0xFF00E676)
        : const Color(0xFFFFD600);

    return OrbitGlassCard(
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Checkbox
              GestureDetector(
                onTap: onToggle,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  width: 26, height: 26,
                  margin: const EdgeInsets.only(top: 2),
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
              ),
              const SizedBox(width: 12),

              // Titel + Beschreibung
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Phase-Badge
                    Container(
                      margin: const EdgeInsets.only(bottom: 5),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: phaseColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: phaseColor.withOpacity(0.45)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            allDone ? Icons.check_circle : Icons.flag_rounded,
                            size: 10, color: phaseColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Phase ${phaseIndex + 1} / $totalPhases',
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
                    // Titel
                    Text(
                      title,
                      style: TextStyle(
                        color: done ? Colors.white.withOpacity(0.45) : Colors.white,
                        fontSize: 15, fontWeight: FontWeight.w700,
                        decoration: done ? TextDecoration.lineThrough : TextDecoration.none,
                        decorationColor: Colors.white.withOpacity(0.35),
                      ),
                    ),
                    if (desc.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        desc,
                        style: TextStyle(
                          color: Colors.white.withOpacity(done ? 0.30 : 0.55),
                          fontSize: 13, fontWeight: FontWeight.w500, height: 1.35,
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

// ──────────────────────────────────────────────────────────────
// Phasen-Header (normale Sektionen)
// ──────────────────────────────────────────────────────────────

class _PhaseHeader extends StatelessWidget {
  final String label;
  final int done, total;
  const _PhaseHeader({required this.label, required this.done, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF7C4DFF).withOpacity(0.20),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF9C6FFF).withOpacity(0.40)),
          ),
          child: Text(
            label.toUpperCase(),
            style: TextStyle(
              color: const Color(0xFF9C6FFF).withOpacity(0.90),
              fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2,
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
              valueColor: const AlwaysStoppedAnimation(Color(0xFF9C6FFF)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text('$done/$total',
            style: TextStyle(
              color: Colors.white.withOpacity(0.40),
              fontSize: 11, fontWeight: FontWeight.w600,
            )),
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
          icon: Icon(Icons.arrow_back, color: Colors.white.withOpacity(0.90)),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            title,
            maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 22, fontWeight: FontWeight.w900,
              color: Colors.white, letterSpacing: -0.3,
            ),
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Normale Auftrags-Karte
// ──────────────────────────────────────────────────────────────

class _TaskCard extends StatelessWidget {
  final String title, desc;
  final bool done;
  final VoidCallback onToggle;

  const _TaskCard({
    required this.title, required this.desc,
    required this.done, required this.onToggle,
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
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: done ? Colors.white.withOpacity(0.45) : Colors.white,
                        fontSize: 15, fontWeight: FontWeight.w700,
                        decoration: done ? TextDecoration.lineThrough : TextDecoration.none,
                        decorationColor: Colors.white.withOpacity(0.35),
                      ),
                    ),
                    if (desc.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        desc,
                        style: TextStyle(
                          color: Colors.white.withOpacity(done ? 0.30 : 0.55),
                          fontSize: 13, fontWeight: FontWeight.w500, height: 1.35,
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
