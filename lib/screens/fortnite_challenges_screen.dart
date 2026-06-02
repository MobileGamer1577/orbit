import 'package:flutter/material.dart';

import '../services/fortnite_challenges_service.dart';
import '../theme/orbit_theme.dart';
import '../widgets/orbit_glass_card.dart';

// ══════════════════════════════════════════════════════════════
//
//  📋 FORTNITE CHALLENGES SCREEN
//  Datei: lib/screens/fortnite_challenges_screen.dart
//
//  Zeigt aktuelle Fortnite Aufträge von fortnite-api.com.
//  Kein API-Key nötig.
//
//  UI-Konzept:
//    • FutureBuilder lädt die Daten beim ersten Öffnen
//    • Gruppenweise Anzeige (Woche 1, Täglich, etc.)
//    • XP-Badge pro Auftrag
//    • Refresh-Button oben rechts
//
// ══════════════════════════════════════════════════════════════

class FortniteChallengessScreen extends StatefulWidget {
  const FortniteChallengessScreen({super.key});

  @override
  State<FortniteChallengessScreen> createState() =>
      _FortniteChallengessScreenState();
}

class _FortniteChallengessScreenState
    extends State<FortniteChallengessScreen> {

  // Future wird in einer Variable gespeichert damit
  // es nur einmal gestartet wird (nicht bei jedem rebuild)
  late Future<List<FnBundle>> _future;

  @override
  void initState() {
    super.initState();
    _future = FortniteChallengessService.fetchBundles();
  }

  /// Löst einen Neu-Laden aus (z.B. nach Refresh-Tap)
  void _reload() {
    setState(() {
      _future = FortniteChallengessService.fetchBundles();
    });
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
                      icon: Icon(Icons.arrow_back,
                          color: Colors.white.withOpacity(0.90)),
                    ),
                    const SizedBox(width: 4),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Live Aufträge',
                            style: TextStyle(
                              fontSize:      24,
                              fontWeight:    FontWeight.w900,
                              color:         Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                          Text(
                            'fortnite-api.com · Aktuell',
                            style: TextStyle(
                              fontSize:   12,
                              color:      Colors.white54,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Refresh-Button
                    IconButton(
                      onPressed: _reload,
                      icon: Icon(Icons.refresh,
                          color: Colors.white.withOpacity(0.70)),
                      tooltip: 'Neu laden',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // ── Inhalt via FutureBuilder ────────────────
              //
              //  FutureBuilder verwaltet automatisch die drei Zustände:
              //    1. Laden  → CircularProgressIndicator
              //    2. Fehler → Fehlermeldung + Retry
              //    3. Daten  → Auftrags-Liste
              //
              Expanded(
                child: FutureBuilder<List<FnBundle>>(
                  future: _future,
                  builder: (context, snapshot) {

                    // ── 1. Lädt noch ──────────────────────
                    if (snapshot.connectionState != ConnectionState.done) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(
                                color: Color(0xFF9C6FFF)),
                            const SizedBox(height: 16),
                            Text(
                              'Aufträge werden geladen…',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.55),
                                  fontSize: 14),
                            ),
                          ],
                        ),
                      );
                    }

                    // ── 2. Fehler ─────────────────────────
                    if (snapshot.hasError) {
                      return _ErrorView(
                        error:   snapshot.error.toString(),
                        onRetry: _reload,
                      );
                    }

                    final bundles = snapshot.data ?? [];

                    // ── 3a. Keine Daten ───────────────────
                    if (bundles.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.inbox_outlined,
                                  color: Colors.white.withOpacity(0.20),
                                  size: 52),
                              const SizedBox(height: 16),
                              Text(
                                'Keine Aufträge gefunden.',
                                style: TextStyle(
                                  color:      Colors.white.withOpacity(0.55),
                                  fontSize:   16,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Die API liefert gerade keine Daten.\n'
                                'Möglicherweise gibt es eine neue Season.',
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.35),
                                    fontSize: 13,
                                    height: 1.4),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              FilledButton.icon(
                                onPressed: _reload,
                                style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFF9C6FFF)),
                                icon:  const Icon(Icons.refresh),
                                label: const Text('Erneut versuchen'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    // ── 3b. Daten vorhanden ───────────────
                    return _BundleList(bundles: bundles);
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
//  _BundleList — Liste aller Gruppen + ihre Aufträge
// ──────────────────────────────────────────────────────────────

class _BundleList extends StatelessWidget {
  final List<FnBundle> bundles;
  const _BundleList({required this.bundles});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics:  const BouncingScrollPhysics(),
      padding:  const EdgeInsets.fromLTRB(16, 4, 16, 32),
      itemCount: bundles.length,
      itemBuilder: (context, i) => _BundleSection(bundle: bundles[i]),
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  _BundleSection — Eine Gruppe (z.B. "Woche 1") mit Aufträgen
// ──────────────────────────────────────────────────────────────

class _BundleSection extends StatelessWidget {
  final FnBundle bundle;
  const _BundleSection({required this.bundle});

  // XP-Summe aller Aufträge in diesem Bundle berechnen
  int get _totalXp =>
      bundle.quests.fold(0, (sum, q) => sum + q.xp);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),

        // ── Gruppen-Header ─────────────────────────────
        Row(
          children: [
            // Label-Badge (z.B. "WOCHE 1")
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color:        const Color(0xFF7C4DFF).withOpacity(0.20),
                borderRadius: BorderRadius.circular(8),
                border:       Border.all(
                    color: const Color(0xFF9C6FFF).withOpacity(0.40)),
              ),
              child: Text(
                bundle.label.toUpperCase(),
                style: TextStyle(
                  color:         const Color(0xFF9C6FFF).withOpacity(0.90),
                  fontSize:      10,
                  fontWeight:    FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Anzahl Aufträge
            Text(
              '${bundle.quests.length} Aufträge',
              style: TextStyle(
                color:      Colors.white.withOpacity(0.35),
                fontSize:   12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),

            // XP-Summe des Bundles
            if (_totalXp > 0)
              Row(
                children: [
                  Icon(Icons.bolt,
                      size: 14,
                      color: const Color(0xFFFFD600).withOpacity(0.80)),
                  const SizedBox(width: 3),
                  Text(
                    _fmtXp(_totalXp),
                    style: const TextStyle(
                      color:      Color(0xFFFFD600),
                      fontSize:   12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
          ],
        ),

        const SizedBox(height: 10),

        // ── Auftrags-Karten ────────────────────────────
        ...bundle.quests.asMap().entries.map((e) {
          final isLast = e.key == bundle.quests.length - 1;
          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
            child: _QuestCard(quest: e.value),
          );
        }),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  _QuestCard — Einzelne Auftrags-Karte
// ──────────────────────────────────────────────────────────────

class _QuestCard extends StatelessWidget {
  final FnQuest quest;
  const _QuestCard({required this.quest});

  @override
  Widget build(BuildContext context) {
    return OrbitGlassCard(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Checkbox-ähnlicher Kreis (rein visuell, kein Zustand)
            Container(
              width: 26, height: 26,
              margin: const EdgeInsets.only(top: 1),
              decoration: BoxDecoration(
                color:        Colors.white.withOpacity(0.07),
                borderRadius: BorderRadius.circular(8),
                border:       Border.all(
                    color: Colors.white.withOpacity(0.20), width: 1.5),
              ),
            ),
            const SizedBox(width: 14),

            // Auftrags-Inhalt
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Name
                  Text(
                    quest.name,
                    style: const TextStyle(
                      color:      Colors.white,
                      fontSize:   15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  // Beschreibung (optional)
                  if (quest.description.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      quest.description,
                      style: TextStyle(
                        color:      Colors.white.withOpacity(0.55),
                        fontSize:   13,
                        fontWeight: FontWeight.w500,
                        height:     1.35,
                      ),
                    ),
                  ],

                  // XP-Badge
                  if (quest.xp > 0) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bolt,
                            size: 13,
                            color: const Color(0xFFFFD600).withOpacity(0.90)),
                        const SizedBox(width: 3),
                        Text(
                          '${_fmtXp(quest.xp)} XP',
                          style: const TextStyle(
                            color:      Color(0xFFFFD600),
                            fontSize:   12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  Fehler-Ansicht
// ──────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded,
                color: Colors.white24, size: 52),
            const SizedBox(height: 16),
            const Text(
              'Aufträge konnten nicht geladen werden.',
              style: TextStyle(
                  color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.40), fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF7C4DFF)),
              icon:  const Icon(Icons.refresh),
              label: const Text('Erneut versuchen'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Hilfsfunktion: XP formatieren ─────────────────────────────
String _fmtXp(int xp) {
  if (xp >= 1000000) return '${(xp / 1000000).toStringAsFixed(1)}M';
  if (xp >= 1000)    return '${(xp / 1000).toStringAsFixed(0)}k';
  return '$xp';
}
