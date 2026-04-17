import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../storage/task_store.dart';
import '../theme/orbit_theme.dart';
import '../widgets/orbit_glass_card.dart';

// ══════════════════════════════════════════════════════════════
//
//  📊 DINO STATS SYSTEM
//  Datei: lib/screens/dino_stats_screen.dart
//
//  Drei Screens in einer Datei:
//    DinoStatsHubScreen   → Hub mit zwei Buttons
//    DinoDexStatsScreen   → Fortschritt + Aufschlüsselung
//    DinoLeaderboardScreen → Bestenliste aus JSON
//
//  ✏️  ERWEITERBAR:
//    → Neue Stats-Screens: hier unten anhängen + Hub-Button ergänzen
//    → Neue Leaderboard-Einträge: in leaderboard.json eintragen
//
// ══════════════════════════════════════════════════════════════


// ──────────────────────────────────────────────────────────────
//  Rarity-System — muss mit dino_dex_screen.dart übereinstimmen
//  ⚠️  Wenn du Seltenheiten änderst, hier UND in dino_dex_screen
//      anpassen!
// ──────────────────────────────────────────────────────────────

const _rarityOrder = ['common', 'rare', 'epic', 'legendary', 'jurassic'];

const _rarityColors = {
  'common':    Color(0xFF8F8F8F),
  'rare':      Color(0xFF0077FF),
  'epic':      Color(0xFF9B59B6),
  'legendary': Color(0xFFFF8C00),
  'jurassic':  Color(0xFFFFD700),
};

const _rarityLabels = {
  'common':    'Common',
  'rare':      'Rare',
  'epic':      'Epic',
  'legendary': 'Legendary',
  'jurassic':  'Jurassic',
};

Color _rarityColor(String r) =>
    _rarityColors[r.toLowerCase()] ?? const Color(0xFF8F8F8F);
String _rarityLabel(String r) =>
    _rarityLabels[r.toLowerCase()] ?? r;


// ══════════════════════════════════════════════════════════════
//  SCREEN 1: DinoStatsHubScreen — Auswahl-Hub
// ══════════════════════════════════════════════════════════════

class DinoStatsHubScreen extends StatelessWidget {
  const DinoStatsHubScreen({super.key});

  void _push(BuildContext context, Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: OrbitBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Header ─────────────────────────────────
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.arrow_back,
                        color: Colors.white.withOpacity(0.90),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '📊 Stats',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                          Text(
                            'Klau die Dinos',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white54,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    children: [

                      // ── Button 1: Dino Dex Stats ─────────
                      _StatsCard(
                        icon: Icons.bar_chart,
                        iconColor: const Color(0xFF9C6FFF),
                        title: 'Dino Dex Stats',
                        subtitle: 'Fortschritt & Aufschlüsselung nach Seltenheit',
                        onTap: () => _push(context, const DinoDexStatsScreen()),
                      ),
                      const SizedBox(height: 12),

                      // ── Button 2: Bestenliste ─────────────
                      _StatsCard(
                        icon: Icons.emoji_events,
                        iconColor: const Color(0xFFFFD700),
                        title: '🏆 Bestenliste',
                        subtitle: 'Top-Spieler nach Rebirths',
                        onTap: () => _push(context, const DinoLeaderboardScreen()),
                      ),

                      // ══════════════════════════════════════
                      // ✏️  WEITERE STATS-SCREENS HIER:
                      //
                      // const SizedBox(height: 12),
                      // _StatsCard(
                      //   icon: Icons.timeline,
                      //   iconColor: const Color(0xFF00E676),
                      //   title: 'Mein Screen',
                      //   subtitle: 'Beschreibung',
                      //   onTap: () => _push(context, MeinStatsScreen()),
                      // ),
                      // ══════════════════════════════════════

                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _StatsCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OrbitGlassCard(
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 18, 12, 18),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: iconColor.withOpacity(0.35), width: 1.2),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.55),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.white.withOpacity(0.35),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// ══════════════════════════════════════════════════════════════
//  SCREEN 2: DinoDexStatsScreen — Fortschritt + Seltenheits-Aufschlüsselung
// ══════════════════════════════════════════════════════════════

class DinoDexStatsScreen extends StatefulWidget {
  const DinoDexStatsScreen({super.key});

  @override
  State<DinoDexStatsScreen> createState() => _DinoDexStatsScreenState();
}

class _DinoDexStatsScreenState extends State<DinoDexStatsScreen> {
  // Gesamtzahlen
  int _totalDinos  = 0;
  int _ownedDinos  = 0;

  // Aufschlüsselung pro Seltenheit: { 'common': (gesamt, owned), ... }
  final Map<String, (int, int)> _byRarity = {};

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      // Beide JSON-Dateien laden
      final results = await Future.wait([
        rootBundle.loadString('assets/data/dino_dex.json'),
        rootBundle.loadString('assets/data/dinos_database.json'),
      ]);

      final dexJson = jsonDecode(results[0]) as Map<String, dynamic>;
      final dinoDb  = jsonDecode(results[1]) as Map<String, dynamic>;

      int total = 0;
      int owned = 0;
      final byRarity = <String, (int, int)>{};

      // Alle Kategorien + alle Dino-IDs durchgehen
      final categories = dexJson['categories'] as List? ?? [];
      for (final cat in categories) {
        final dinoIds = (cat['dinos'] as List?)?.cast<String>() ?? [];
        for (final id in dinoIds) {
          final data   = dinoDb[id] as Map<String, dynamic>?;
          final rarity = (data?['rarity'] as String?) ?? 'common';
          final isDone = TaskStore.isDone('dino:$id');

          total++;
          if (isDone) owned++;

          // Zähler pro Seltenheit aktualisieren
          final current = byRarity[rarity] ?? (0, 0);
          byRarity[rarity] = (
            current.$1 + 1,              // gesamt
            current.$2 + (isDone ? 1 : 0) // owned
          );
        }
      }

      if (mounted) {
        setState(() {
          _totalDinos = total;
          _ownedDinos = owned;
          _byRarity
            ..clear()
            ..addAll(byRarity);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = _totalDinos == 0 ? 0.0 : _ownedDinos / _totalDinos;
    final percent  = (progress * 100).toStringAsFixed(1);

    // Seltenheiten in definierter Reihenfolge ausgeben
    final sortedRarities = _rarityOrder
        .where(_byRarity.containsKey)
        .toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: OrbitBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Header ─────────────────────────────────
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
                    const Text(
                      'Dino Dex Stats',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF9C6FFF),
                        ),
                      )
                    : ListView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                        children: [

                          // ── Gesamt-Karte ────────────────
                          OrbitGlassCard(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Gesammelt',
                                          style: TextStyle(
                                            color: Colors.white
                                                .withOpacity(0.55),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              '$_ownedDinos',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 40,
                                                fontWeight: FontWeight.w900,
                                                height: 1.0,
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 5,
                                                left: 4,
                                              ),
                                              child: Text(
                                                '/ $_totalDinos',
                                                style: TextStyle(
                                                  color: Colors.white
                                                      .withOpacity(0.45),
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    // Prozent-Badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF9C6FFF)
                                            .withOpacity(0.18),
                                        borderRadius:
                                            BorderRadius.circular(14),
                                        border: Border.all(
                                          color: const Color(0xFF9C6FFF)
                                              .withOpacity(0.45),
                                        ),
                                      ),
                                      child: Text(
                                        '$percent %',
                                        style: const TextStyle(
                                          color: Color(0xFF9C6FFF),
                                          fontSize: 22,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    minHeight: 8,
                                    backgroundColor:
                                        Colors.white.withOpacity(0.10),
                                    valueColor:
                                        const AlwaysStoppedAnimation(
                                      Color(0xFF9C6FFF),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // ── Aufschlüsselung nach Seltenheit ──
                          Text(
                            'NACH SELTENHEIT',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.38),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.4,
                            ),
                          ),
                          const SizedBox(height: 10),

                          ...sortedRarities.map((rarity) {
                            final (total, owned) = _byRarity[rarity]!;
                            final prog =
                                total == 0 ? 0.0 : owned / total;
                            final color = _rarityColor(rarity);
                            final label = _rarityLabel(rarity);

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: OrbitGlassCard(
                                padding: const EdgeInsets.fromLTRB(
                                    16, 12, 16, 12),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        // Farb-Dot
                                        Container(
                                          width: 10,
                                          height: 10,
                                          decoration: BoxDecoration(
                                            color: color,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: color.withOpacity(0.5),
                                                blurRadius: 4,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          label,
                                          style: TextStyle(
                                            color: color,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          '$owned / $total',
                                          style: TextStyle(
                                            color: Colors.white
                                                .withOpacity(0.60),
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: LinearProgressIndicator(
                                        value: prog,
                                        minHeight: 5,
                                        backgroundColor:
                                            Colors.white.withOpacity(0.09),
                                        valueColor:
                                            AlwaysStoppedAnimation(color),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
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
//  SCREEN 3: DinoLeaderboardScreen — Bestenliste
// ══════════════════════════════════════════════════════════════

class DinoLeaderboardScreen extends StatefulWidget {
  const DinoLeaderboardScreen({super.key});

  @override
  State<DinoLeaderboardScreen> createState() => _DinoLeaderboardScreenState();
}

class _DinoLeaderboardScreenState extends State<DinoLeaderboardScreen> {
  List<_LeaderboardEntry> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final jsonStr =
          await rootBundle.loadString('assets/data/leaderboard.json');
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final raw  = (data['entries'] as List?) ?? [];

      _entries = raw
          .whereType<Map<String, dynamic>>()
          .map((e) => _LeaderboardEntry(
                name:     (e['name']     as String?) ?? '???',
                rebirths: (e['rebirths'] as int?)    ?? 0,
              ))
          .toList()
        ..sort((a, b) => b.rebirths.compareTo(a.rebirths));
      // ↑ absteigend nach Rebirths sortieren
    } catch (_) {
      _entries = [];
    }

    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: OrbitBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Header ─────────────────────────────────
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
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '🏆 Bestenliste',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                          Text(
                            'Klau die Dinos — Top Rebirths',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white54,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ── Liste ──────────────────────────────────
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFFFD700),
                        ),
                      )
                    : _entries.isEmpty
                        ? Center(
                            child: Text(
                              'Keine Einträge.',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.45),
                              ),
                            ),
                          )
                        : ListView.separated(
                            physics: const BouncingScrollPhysics(),
                            padding:
                                const EdgeInsets.fromLTRB(16, 4, 16, 32),
                            itemCount: _entries.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, i) {
                              return _LeaderboardTile(
                                rank:  i + 1,
                                entry: _entries[i],
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
//  Datenmodell für Bestenliste
// ──────────────────────────────────────────────────────────────

class _LeaderboardEntry {
  final String name;
  final int    rebirths;

  const _LeaderboardEntry({required this.name, required this.rebirths});
}

// ──────────────────────────────────────────────────────────────
//  Bestenlisten-Eintrag
// ──────────────────────────────────────────────────────────────

class _LeaderboardTile extends StatelessWidget {
  final int               rank;
  final _LeaderboardEntry entry;

  const _LeaderboardTile({required this.rank, required this.entry});

  @override
  Widget build(BuildContext context) {
    // Top 3 bekommen besondere Farben
    final (rankColor, rankIcon) = switch (rank) {
      1 => (const Color(0xFFFFD700), '🥇'), // Gold
      2 => (const Color(0xFFB0C4D8), '🥈'), // Silber
      3 => (const Color(0xFFCD7F32), '🥉'), // Bronze
      _ => (Colors.white.withOpacity(0.30), ''),
    };

    return OrbitGlassCard(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          children: [

            // Rang
            SizedBox(
              width: 42,
              child: rank <= 3
                  ? Text(
                      rankIcon,
                      style: const TextStyle(fontSize: 26),
                      textAlign: TextAlign.center,
                    )
                  : Text(
                      '#$rank',
                      style: TextStyle(
                        color: rankColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
            ),

            const SizedBox(width: 12),

            // Name
            Expanded(
              child: Text(
                entry.name,
                style: TextStyle(
                  color: rank <= 3
                      ? Colors.white
                      : Colors.white.withOpacity(0.85),
                  fontWeight:
                      rank <= 3 ? FontWeight.w900 : FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),

            // Rebirths-Badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: rankColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: rankColor.withOpacity(0.40)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.refresh_rounded,
                    size: 13,
                    color: rankColor,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${entry.rebirths}',
                    style: TextStyle(
                      color: rankColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
