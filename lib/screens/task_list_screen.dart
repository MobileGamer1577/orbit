import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../l10n/app_localizations.dart';
import '../storage/task_store.dart';
import '../theme/orbit_theme.dart';
import '../widgets/orbit_glass_card.dart';

// ──────────────────────────────────────────────────────────────
// Interne Datenmodelle
// ──────────────────────────────────────────────────────────────

class _QuestItem {
  final String id;
  final String title;
  final String description;

  const _QuestItem({
    required this.id,
    required this.title,
    required this.description,
  });
}

class _Phase {
  final int    phase;
  final String label;
  final List<_QuestItem> quests;

  const _Phase({
    required this.phase,
    required this.label,
    required this.quests,
  });
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
  List<_Phase> _phases   = [];
  bool         _loading  = true;
  bool         _empty    = false;   // leere phases-Liste
  String       _query    = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() => _query = _searchCtrl.text));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Hier laden, weil wir Locale brauchen → erst nach initState verfügbar
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
      // Sprache aus aktuellem Locale (z.B. 'de' oder 'en')
      final lang = Localizations.localeOf(context).languageCode;

      // Beide Dateien parallel laden
      final results = await Future.wait([
        rootBundle.loadString(path),
        rootBundle.loadString('assets/data/quests_database.json'),
      ]);

      final modeData = jsonDecode(results[0]) as Map<String, dynamic>;
      final db       = jsonDecode(results[1]) as Map<String, dynamic>;

      // Neues Format: { "phases": [...] }
      if (modeData.containsKey('phases')) {
        final rawPhases = modeData['phases'] as List;

        if (rawPhases.isEmpty) {
          if (mounted) setState(() { _loading = false; _empty = true; });
          return;
        }

        final phases = rawPhases.map((p) {
          // Phase-Label übersetzen
          final labelMap = p['label'];
          final String label;
          if (labelMap is Map) {
            label = (labelMap[lang] ?? labelMap['de'] ?? '') as String;
          } else {
            label = labelMap?.toString() ?? '';
          }

          // Aufträge aus DB laden
          final questIds = (p['quests'] as List).cast<String>();
          final quests = questIds.map((id) {
            final entry = db[id];
            if (entry == null) {
              return _QuestItem(id: id, title: id, description: '');
            }
            final langData = (entry[lang] ?? entry['de']) as Map<String, dynamic>;
            return _QuestItem(
              id:          id,
              title:       (langData['title']       as String?) ?? id,
              description: (langData['description'] as String?) ?? '',
            );
          }).toList();

          return _Phase(
            phase:  (p['phase'] as num).toInt(),
            label:  label,
            quests: quests,
          );
        }).toList();

        if (mounted) setState(() { _phases = phases; _loading = false; });

      } else {
        // Altes Format als Fallback: { "tasks": [...] } — bleibt kompatibel
        final tasks = (modeData['tasks'] as List?)?.cast<Map>() ?? [];
        final quests = tasks.map((t) => _QuestItem(
          id:          (t['id'] as String?) ?? '',
          title:       (t['title'] as String?) ?? '',
          description: (t['description'] as String?) ?? '',
        )).toList();

        final phase = _Phase(phase: 1, label: '', quests: quests);
        if (mounted) setState(() { _phases = [phase]; _loading = false; });
      }
    } catch (_) {
      if (mounted) setState(() { _loading = false; _empty = true; });
    }
  }

  // ── Filter ─────────────────────────────────────────────────

  List<_Phase> _filteredPhases() {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _phases;

    return _phases.map((phase) {
      final matching = phase.quests.where((quest) {
        return quest.title.toLowerCase().contains(q) ||
               quest.description.toLowerCase().contains(q);
      }).toList();
      return _Phase(phase: phase.phase, label: phase.label, quests: matching);
    }).where((phase) => phase.quests.isNotEmpty).toList();
  }

  int get _totalQuests =>
      _phases.fold(0, (sum, p) => sum + p.quests.length);

  int get _doneQuests => _phases.fold(0, (sum, p) {
    return sum + p.quests.where((q) => TaskStore.isDone(q.id)).length;
  });

  // ── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    // Ladeindikator
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF10041E),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF7C4DFF)),
        ),
      );
    }

    // „Kommt bald" — wenn Pfad leer oder phases leer
    if (_empty || _phases.isEmpty) {
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
                          Text(
                            l10n.taskComingSoon,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
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

    final filtered    = _filteredPhases();
    final total       = _totalQuests;
    final done        = _doneQuests;
    final progress    = total == 0 ? 0.0 : done / total;
    final visibleCount = filtered.fold(0, (s, p) => s + p.quests.length);

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
                    // Gesamtfortschritt
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
                        Text(
                          '$done / $total',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.75),
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Suchfeld
                    OrbitGlassCard(
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 4),
                        child: Row(
                          children: [
                            Icon(Icons.search,
                                color: Colors.white.withOpacity(0.55),
                                size: 20),
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
                    Text(
                      l10n.taskQuestCount(visibleCount),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.38),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Phasen-Liste ──────────────────────────────
              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: filtered.length,
                  itemBuilder: (context, phaseIndex) {
                    final phase = filtered[phaseIndex];
                    return _PhaseSection(
                      phase:   phase,
                      onToggle: (id, current) async {
                        await TaskStore.setDone(id, !current);
                        if (mounted) setState(() {});
                      },
                    );
                  },
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
// Phasen-Abschnitt mit Header + Karten
// ──────────────────────────────────────────────────────────────

class _PhaseSection extends StatelessWidget {
  final _Phase phase;
  final Future<void> Function(String id, bool currentDone) onToggle;

  const _PhaseSection({required this.phase, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final doneInPhase =
        phase.quests.where((q) => TaskStore.isDone(q.id)).length;
    final total = phase.quests.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Phasen-Header ─────────────────────────────────
        if (phase.label.isNotEmpty) ...[
          const SizedBox(height: 20),
          Row(
            children: [
              // Phasen-Badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C4DFF).withOpacity(0.20),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF9C6FFF).withOpacity(0.40),
                  ),
                ),
                child: Text(
                  phase.label.toUpperCase(),
                  style: TextStyle(
                    color: const Color(0xFF9C6FFF).withOpacity(0.90),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Mini-Fortschritt der Phase
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: total == 0 ? 0 : doneInPhase / total,
                    minHeight: 4,
                    backgroundColor: Colors.white.withOpacity(0.08),
                    valueColor: const AlwaysStoppedAnimation(
                        Color(0xFF9C6FFF)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$doneInPhase/$total',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.40),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ] else
          const SizedBox(height: 8),

        // ── Auftrags-Karten ───────────────────────────────
        ...phase.quests.asMap().entries.map((entry) {
          final i    = entry.key;
          final quest = entry.value;
          final done  = TaskStore.isDone(quest.id);
          return Padding(
            padding: EdgeInsets.only(bottom: i < phase.quests.length - 1 ? 10 : 0),
            child: _TaskCard(
              title:    quest.title,
              desc:     quest.description,
              done:     done,
              onToggle: () => onToggle(quest.id, done),
            ),
          );
        }),
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
  final bool   done;
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
