import 'dart:io';
import 'package:flutter/material.dart';

import '../services/opsucht_sync_service.dart';
import '../theme/orbit_theme.dart';
import '../widgets/orbit_glass_card.dart';

// ══════════════════════════════════════════════════════════════
//
//  🎟️ OPSUCHT OPPASS SCREEN
//  Datei: lib/screens/opsucht_oppass_screen.dart
//
//  Horizontale Swipe-Galerie für OPPASS Season Bilder.
//  Bilder kommen aus dem lokalen GitHub-Cache (keine Assets).
//
//  Änderungen:
//    • Kein Vollbild-Screen mehr beim Tap
//    • Stattdessen: InteractiveViewer inline (Pinch-to-Zoom)
//    • Keine abgerundeten Ecken auf den Bildern
//
//  Bilder-Quelle:
//    GitHub Raw: lib/opsucht/oppass/1.png ... N.png
//    Lokal gecacht in: getApplicationDocumentsDirectory()/opsucht/oppass/
//
// ══════════════════════════════════════════════════════════════

class OpSuchtOppassScreen extends StatefulWidget {
  const OpSuchtOppassScreen({super.key});

  @override
  State<OpSuchtOppassScreen> createState() => _OpSuchtOppassScreenState();
}

class _OpSuchtOppassScreenState extends State<OpSuchtOppassScreen> {
  final PageController _pageCtrl = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    final service = OpSuchtSyncService.instance;
    service.addListener(_onUpdate);

    // Season + Bilder laden falls noch nicht geladen
    if (!service.seasonLoaded) {
      service.loadSeason();
    }
  }

  @override
  void dispose() {
    OpSuchtSyncService.instance.removeListener(_onUpdate);
    _pageCtrl.dispose();
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final service = OpSuchtSyncService.instance;
    final season  = service.season;
    final images  = service.oppassImages;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: OrbitBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Header ────────────────────────────────
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'OPPASS',
                            style: TextStyle(
                              fontSize:      26,
                              fontWeight:    FontWeight.w900,
                              color:         Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                          // ✅ Format: "[Name] Season" — NICHT "Season Season"
                          Text(
                            '${season.name} Season',
                            style: TextStyle(
                              color:      Colors.white.withOpacity(0.50),
                              fontWeight: FontWeight.w600,
                              fontSize:   14,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Seitenanzeige oben rechts
                    if (images.isNotEmpty)
                      Text(
                        '${_currentPage + 1} / ${images.length}',
                        style: TextStyle(
                          color:      Colors.white.withOpacity(0.60),
                          fontWeight: FontWeight.w700,
                          fontSize:   15,
                        ),
                      ),
                  ],
                ),
              ),

              // ── Countdown-Zeile ───────────────────────
              // Kein OrbitGlassCard drumherum — nur plain Text-Zeile
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
                child: _CountdownRow(season: season),
              ),

              const SizedBox(height: 12),

              // ── Galerie ───────────────────────────────
              Expanded(
                child: !service.seasonLoaded
                    // Laden-Indikator
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFF00D4FF)))
                    : images.isEmpty
                    // Keine Bilder (noch nicht geladen / nicht gefunden)
                    ? _EmptyState(
                        season:  season,
                        syncing: service.syncing,
                      )
                    // ✅ Swipe-Galerie — kein Vollbild, Zoom inline
                    : _Gallery(
                        images:        images,
                        pageCtrl:      _pageCtrl,
                        currentPage:   _currentPage,
                        onPageChanged: (i) => setState(() => _currentPage = i),
                      ),
              ),

              // ── Dots-Indikator ────────────────────────
              if (service.seasonLoaded && images.isNotEmpty)
                _DotsRow(count: images.length, current: _currentPage),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  Countdown-Zeile
//
//  Zeigt verbleibende Zeit in Tagen oder Stunden.
//  Wird rot + animiert wenn < 24h verbleibend.
// ──────────────────────────────────────────────────────────────

class _CountdownRow extends StatefulWidget {
  final OpSuchtSeasonData season;
  const _CountdownRow({required this.season});

  @override
  State<_CountdownRow> createState() => _CountdownRowState();
}

class _CountdownRowState extends State<_CountdownRow>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync:    this,
        duration: const Duration(milliseconds: 900));
    _anim = Tween<double>(begin: 0.75, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    if (widget.season.isEndingVeryLoon) {
      _ctrl.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _text() {
    final rem = widget.season.timeRemaining;
    if (rem.isNegative) return 'Season beendet';
    if (rem.inHours < 24) return '${rem.inHours} Stunden verbleibend';
    return '${rem.inDays} Tage verbleibend';
  }

  @override
  Widget build(BuildContext context) {
    final s     = widget.season;
    final color = s.isEndingVeryLoon
        ? const Color(0xFFFF1744)
        : s.isEndingSoon
        ? const Color(0xFFFF8C00)
        : const Color(0xFF00D4FF);

    return FadeTransition(
      opacity: _anim,
      child: Row(
        children: [
          Icon(Icons.timer_outlined, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            _text(),
            style: TextStyle(
              color:      color,
              fontSize:   13,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (s.isEndingSoon) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color:        color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
                border:       Border.all(color: color.withOpacity(0.45)),
              ),
              child: Text(
                s.isEndingVeryLoon ? '⚠ < 24h' : 'Season endet bald',
                style: TextStyle(
                    color: color, fontSize: 10, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  Horizontale Swipe-Galerie
//
//  ✅ Kein Vollbild mehr beim Tap.
//  ✅ Keine abgerundeten Ecken.
//  ✅ InteractiveViewer ermöglicht Pinch-to-Zoom inline.
// ──────────────────────────────────────────────────────────────

class _Gallery extends StatelessWidget {
  final List<String>      images;
  final PageController    pageCtrl;
  final int               currentPage;
  final ValueChanged<int> onPageChanged;

  const _Gallery({
    required this.images,
    required this.pageCtrl,
    required this.currentPage,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller:    pageCtrl,
      onPageChanged: onPageChanged,
      itemCount:     images.length,
      itemBuilder:   (context, i) {
        return Padding(
          // Kleiner horizontaler Abstand damit man swipen kann
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: InteractiveViewer(
            // Pinch-to-Zoom ohne separaten Vollbild-Screen
            minScale:     0.8,
            maxScale:     5.0,
            clipBehavior: Clip.none,
            child: _LocalImage(path: images[i]),
          ),
        );
      },
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  Lokales Bild-Widget
//
//  ✅ Keine abgerundeten Ecken (kein ClipRRect).
//  Liest gecachte PNG-Datei vom Gerätespeicher.
//  Fehler → Placeholder-Icon statt Crash.
// ──────────────────────────────────────────────────────────────

class _LocalImage extends StatelessWidget {
  final String path;
  const _LocalImage({required this.path});

  @override
  Widget build(BuildContext context) {
    return Image.file(
      File(path),
      // BoxFit.contain zeigt das gesamte Bild ohne Zuschnitt
      fit:          BoxFit.contain,
      errorBuilder: (_, __, ___) => Container(
        color: Colors.white.withOpacity(0.04),
        child: Icon(
          Icons.broken_image_outlined,
          color: Colors.white.withOpacity(0.20),
          size:  48,
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  Dots-Indikator
//
//  • Bis 20 Bilder → animierte Dots (aktiver Dot breiter)
//  • Über 20 Bilder → nur Zahlen ("3 / 25")
// ──────────────────────────────────────────────────────────────

class _DotsRow extends StatelessWidget {
  final int count;
  final int current;
  const _DotsRow({required this.count, required this.current});

  @override
  Widget build(BuildContext context) {
    if (count > 20) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Center(
          child: Text(
            '${current + 1} / $count',
            style: TextStyle(
              color:      Colors.white.withOpacity(0.50),
              fontSize:   13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(count, (i) {
          final active = i == current;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve:    Curves.easeOut,
            margin:   const EdgeInsets.symmetric(horizontal: 3),
            width:    active ? 18 : 6,
            height:   6,
            decoration: BoxDecoration(
              color:        active
                  ? const Color(0xFF00D4FF)
                  : Colors.white.withOpacity(0.22),
              borderRadius: BorderRadius.circular(3),
            ),
          );
        }),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  Empty State
//
//  Wird gezeigt wenn noch keine Bilder geladen sind.
//  Unterscheidet zwischen "lädt noch" und "wirklich leer".
// ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final OpSuchtSeasonData season;
  final bool              syncing;
  const _EmptyState({required this.season, required this.syncing});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (syncing)
              const CircularProgressIndicator(color: Color(0xFF00D4FF))
            else
              Icon(Icons.photo_library_outlined,
                  color: Colors.white.withOpacity(0.18), size: 52),

            const SizedBox(height: 16),

            Text(
              syncing
                  ? 'Bilder werden geladen…'
                  : 'Keine OPPASS Bilder verfügbar.',
              style: TextStyle(
                color:      Colors.white.withOpacity(0.60),
                fontSize:   16,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),

            if (!syncing) ...[
              const SizedBox(height: 8),
              Text(
                'Bilder werden aus GitHub geladen.\n'
                'Stelle sicher dass du online bist.',
                style: TextStyle(
                    color:  Colors.white.withOpacity(0.35),
                    fontSize: 13,
                    height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () =>
                    OpSuchtSyncService.instance.loadSeason(force: true),
                style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF00D4FF).withOpacity(0.80)),
                icon:  const Icon(Icons.refresh),
                label: const Text('Erneut versuchen'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
