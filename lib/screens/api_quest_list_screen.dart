import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/api_quest.dart';
import '../services/quest_manager.dart';
import '../theme/orbit_theme.dart';
import '../widgets/orbit_glass_card.dart';
import 'connections_screen.dart';

// ══════════════════════════════════════════════════════════════
//
//  📋 API QUEST LIST SCREEN
//  Datei: lib/screens/api_quest_list_screen.dart
//
//  Zeigt Quests an, die von der api-fortnite.com API kommen.
//
//  NEU: Zeigt bei 'no_account' einen freundlichen Verbinden-Button
//       statt einer kryptischen Fehlermeldung.
//
// ══════════════════════════════════════════════════════════════

class ApiQuestListScreen extends StatefulWidget {
  final String title;
  final String gameId;
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
    _searchCtrl.addListener(() => setState(() => _query = _searchCtrl.text));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final lang = Localizations.localeOf(context).languageCode;
    _manager = QuestManager(
      gameId: widget.gameId,
      modeId: widget.modeId,
      language: lang,
    );
    _manager.addListener(_onUpdate);
    _manager.load();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _manager.removeListener(_onUpdate);
    _manager.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<QuestSection> _filtered() {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _manager.sections;
    return _manager.sections
        .map((sec) {
          final visible = sec.quests
              .where(
                (quest) =>
                    quest.title.toLowerCase().contains(q) ||
                    quest.description.toLowerCase().contains(q),
              )
              .toList();
          if (visible.isEmpty) return null;
          return QuestSection(
            label: sec.label,
            isMilestone: sec.isMilestone,
            quests: visible,
          );
        })
        .whereType<QuestSection>()
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sections = _filtered();

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
                    if (_manager.state != QuestLoadState.loading)
                      IconButton(
                        icon: _manager.isRefreshing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white54,
                                ),
                              )
                            : Icon(
                                Icons.refresh,
                                color: Colors.white.withOpacity(0.70),
                              ),
                        onPressed: () => _manager.forceRefresh(),
                      ),
                  ],
                ),
              ),

              // ── Fortschritts-Header ────────────────────────
              if (_manager.hasData) _ProgressHeader(manager: _manager),

              // ── Suchfeld ──────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: OrbitGlassCard(
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search,
                          color: Colors.white.withOpacity(0.55),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _searchCtrl,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                            ),
                            decoration: InputDecoration(
                              hintText: l10n.taskSearchHint,
                              hintStyle: TextStyle(
                                color: Colors.white.withOpacity(0.40),
                                fontSize: 15,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 10,
                              ),
                            ),
                          ),
                        ),
                        if (_query.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _searchCtrl.clear();
                              setState(() => _query = '');
                            },
                            child: Icon(
                              Icons.close,
                              color: Colors.white.withOpacity(0.45),
                              size: 18,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              if (_manager.hasData)
                Padding(
                  padding: const EdgeInsets.only(left: 20, bottom: 4, top: 2),
                  child: Text(
                    l10n.taskQuestCount(
                      sections.fold(0, (s, sec) => s + sec.quests.length),
                    ),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.38),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

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
        // ── Spezielle Fälle ───────────────────────────────
        if (_manager.errorMessage == 'no_account') {
          return _NoAccountWidget(onConnected: () => _manager.forceRefresh());
        }
        if (_manager.errorMessage == 'account_invalid') {
          return _InvalidAccountWidget(
            onReconnect: () async {
              await _manager.forceRefresh();
            },
          );
        }
        if (_manager.errorMessage == 'token_expired') {
          return _TokenExpiredWidget(
            onRelogin: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ConnectionsScreen()),
              ).then((_) => _manager.forceRefresh());
            },
          );
        }
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
//  KEIN ACCOUNT VERBUNDEN
// ══════════════════════════════════════════════════════════════

class _NoAccountWidget extends StatelessWidget {
  final VoidCallback onConnected;
  const _NoAccountWidget({required this.onConnected});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFF00D4FF).withOpacity(0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF00D4FF).withOpacity(0.35),
                ),
              ),
              child: const Icon(
                Icons.link_off,
                color: Color(0xFF00D4FF),
                size: 32,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Kein Fortnite-Account verbunden',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Verbinde deinen Epic-Account um Quests automatisch '
              'zu laden. Deine Daten bleiben lokal auf deinem Gerät.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.55),
                fontSize: 14,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ConnectionsScreen()),
                );
                onConnected();
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF00D4FF).withOpacity(0.80),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.link, size: 18),
              label: const Text(
                'Jetzt verbinden',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  ACCOUNT UNGÜLTIG (404)
// ══════════════════════════════════════════════════════════════

class _InvalidAccountWidget extends StatelessWidget {
  final VoidCallback onReconnect;
  const _InvalidAccountWidget({required this.onReconnect});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.person_off_outlined,
              color: Colors.white24,
              size: 52,
            ),
            const SizedBox(height: 16),
            const Text(
              'Account nicht mehr gültig',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Die gespeicherte Account-ID ist nicht mehr gültig. '
              'Bitte verbinde deinen Account erneut.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.55),
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ConnectionsScreen()),
              ).then((_) => onReconnect()),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF7C4DFF),
              ),
              icon: const Icon(Icons.link),
              label: const Text('Neu verbinden'),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  FORTSCHRITTS-HEADER
// ══════════════════════════════════════════════════════════════

class _ProgressHeader extends StatelessWidget {
  final QuestManager manager;
  const _ProgressHeader({required this.manager});

  String _fmt(int xp) {
    if (xp >= 1000000) return '${(xp / 1000000).toStringAsFixed(1)}M';
    if (xp >= 1000) return '${(xp / 1000).toStringAsFixed(0)}k';
    return '$xp';
  }

  @override
  Widget build(BuildContext context) {
    final progress = manager.totalXp == 0
        ? 0.0
        : manager.earnedXp / manager.totalXp;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: OrbitGlassCard(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          children: [
            Row(
              children: [
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
                        '${manager.doneQuestCount} / ${manager.totalQuestCount}',
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
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      Icons.bolt,
                      size: 18,
                      color: const Color(0xFFFFD600).withOpacity(0.90),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_fmt(manager.earnedXp)} / ${_fmt(manager.totalXp)} XP',
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
//  QUEST-LISTE
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
      itemBuilder: (context, i) =>
          _SectionWidget(section: sections[i], manager: manager),
    );
  }
}

class _SectionWidget extends StatelessWidget {
  final QuestSection section;
  final QuestManager manager;
  const _SectionWidget({required this.section, required this.manager});

  @override
  Widget build(BuildContext context) {
    int done = 0, total = 0;
    for (final q in section.quests) {
      if (q.isMilestone) {
        total += q.stages.length.clamp(1, 999);
        done += q.stages
            .where((s) => manager.isStageChecked(q.id, s.stage))
            .length;
      } else {
        total++;
        if (manager.isChecked(q.id)) done++;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 18),
        Row(
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
        ...section.quests.asMap().entries.map((e) {
          final last = e.key == section.quests.length - 1;
          final q = e.value;
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
//  QUEST-KARTEN (Normal + Milestone)
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
              _Checkbox(done: done, color: const Color(0xFF7C4DFF)),
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
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        decoration: done ? TextDecoration.lineThrough : null,
                        decorationColor: Colors.white.withOpacity(0.35),
                      ),
                    ),
                    if (quest.description.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        quest.description,
                        style: TextStyle(
                          color: Colors.white.withOpacity(done ? 0.30 : 0.55),
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

class _MilestoneCard extends StatelessWidget {
  final ApiQuest quest;
  final QuestManager manager;
  const _MilestoneCard({required this.quest, required this.manager});

  @override
  Widget build(BuildContext context) {
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
                _Checkbox(done: done, color: const Color(0xFFFFD600)),
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
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          decoration: done ? TextDecoration.lineThrough : null,
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

    int activeIdx = quest.stages.indexWhere(
      (s) => !manager.isStageChecked(quest.id, s.stage),
    );
    if (activeIdx == -1) activeIdx = quest.stages.length - 1;

    final allDone =
        activeIdx == quest.stages.length - 1 &&
        manager.isStageChecked(quest.id, quest.stages.last.stage);
    final stage = quest.stages[activeIdx];
    final isDone = manager.isStageChecked(quest.id, stage.stage);
    final phaseColor = allDone
        ? const Color(0xFF00E676)
        : const Color(0xFFFFD600);

    return OrbitGlassCard(
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => manager.setStageChecked(quest.id, stage.stage, !isDone),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Checkbox(done: isDone, color: const Color(0xFFFFD600)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(bottom: 5),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
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
                            size: 10,
                            color: phaseColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Phase ${stage.stage} / ${quest.stages.length}',
                            style: TextStyle(
                              color: phaseColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      quest.title,
                      style: TextStyle(
                        color: isDone
                            ? Colors.white.withOpacity(0.45)
                            : Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        decoration: isDone ? TextDecoration.lineThrough : null,
                        decorationColor: Colors.white.withOpacity(0.35),
                      ),
                    ),
                    if (stage.description.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        stage.description,
                        style: TextStyle(
                          color: Colors.white.withOpacity(isDone ? 0.30 : 0.55),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          height: 1.35,
                        ),
                      ),
                    ],
                    if (quest.xp > 0) ...[
                      const SizedBox(height: 5),
                      _XpBadge(xp: quest.xp, earned: allDone),
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

class _TokenExpiredWidget extends StatelessWidget {
  final VoidCallback onRelogin;
  const _TokenExpiredWidget({required this.onRelogin});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_clock, color: Colors.white24, size: 52),
            const SizedBox(height: 16),
            const Text(
              'Anmeldung abgelaufen',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Dein Fortnite-Login ist abgelaufen.\n'
              'Bitte melde dich erneut an.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.55),
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRelogin,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF00D4FF).withOpacity(0.80),
              ),
              icon: const Icon(Icons.login),
              label: const Text('Erneut anmelden'),
            ),
          ],
        ),
      ),
    );
  }
}
// ══════════════════════════════════════════════════════════════
//  KLEINE HILFS-WIDGETS
// ══════════════════════════════════════════════════════════════

class _Checkbox extends StatelessWidget {
  final bool done;
  final Color color;
  const _Checkbox({required this.done, required this.color});

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 180),
    curve: Curves.easeOut,
    width: 26,
    height: 26,
    margin: const EdgeInsets.only(top: 1),
    decoration: BoxDecoration(
      color: done ? color.withOpacity(0.85) : Colors.white.withOpacity(0.08),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: done ? color : Colors.white.withOpacity(0.22),
        width: 1.5,
      ),
    ),
    child: done ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
  );
}

class _XpBadge extends StatelessWidget {
  final int xp;
  final bool earned;
  const _XpBadge({required this.xp, required this.earned});

  String _fmt(int v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}k';
    return '$v';
  }

  @override
  Widget build(BuildContext context) {
    final c = earned ? const Color(0xFF00E676) : const Color(0xFFFFD600);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.bolt, size: 13, color: c),
        const SizedBox(width: 3),
        Text(
          '${_fmt(xp)} XP',
          style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

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
            const Icon(
              Icons.cloud_off_rounded,
              color: Colors.white24,
              size: 52,
            ),
            const SizedBox(height: 16),
            const Text(
              'Quests konnten nicht geladen werden',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
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
            const SizedBox(height: 24),
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
