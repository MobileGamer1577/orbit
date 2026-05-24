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
//  Fullscreen-Zoom bei Tap.
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

    // Bilder laden falls noch nicht geladen
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

  void _openFullscreen(BuildContext context, String path, int index,
      List<String> paths) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FullscreenGallery(
          paths:        paths,
          initialIndex: index,
        ),
      ),
    );
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
                              fontSize:   26,
                              fontWeight: FontWeight.w900,
                              color:      Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
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
                    // Seitenanzeige
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

              // ── Countdown Badge ───────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
                child: _CountdownRow(season: season),
              ),

              const SizedBox(height: 12),

              // ── Galerie ───────────────────────────────
              Expanded(
                child: !service.seasonLoaded
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFF00D4FF)))
                    : images.isEmpty
                    ? _EmptyState(season: season)
                    : _Gallery(
                        images:      images,
                        pageCtrl:    _pageCtrl,
                        currentPage: _currentPage,
                        onPageChanged: (i) =>
                            setState(() => _currentPage = i),
                        onTap: (i) => _openFullscreen(
                            context, images[i], i, images),
                      ),
              ),

              // ── Dots Indikator ────────────────────────
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
        vsync: this, duration: const Duration(milliseconds: 900));
    _anim = Tween<double>(begin: 0.8, end: 1.0).animate(
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
//  Galerie (horizontales PageView)
// ──────────────────────────────────────────────────────────────

class _Gallery extends StatelessWidget {
  final List<String>  images;
  final PageController pageCtrl;
  final int           currentPage;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onTap;

  const _Gallery({
    required this.images,
    required this.pageCtrl,
    required this.currentPage,
    required this.onPageChanged,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller:    pageCtrl,
      onPageChanged: onPageChanged,
      itemCount:     images.length,
      itemBuilder:   (context, i) {
        return GestureDetector(
          onTap: () => onTap(i),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Hero(
              tag: 'oppass_$i',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: _LocalImage(path: images[i]),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  Lokales Bild-Widget
// ──────────────────────────────────────────────────────────────

class _LocalImage extends StatelessWidget {
  final String path;
  const _LocalImage({required this.path});

  @override
  Widget build(BuildContext context) {
    return Image.file(
      File(path),
      fit:          BoxFit.contain,
      errorBuilder: (_, __, ___) => Container(
        color: Colors.white.withOpacity(0.05),
        child: Icon(
          Icons.broken_image_outlined,
          color: Colors.white.withOpacity(0.25),
          size: 48,
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  Dots-Indikator
// ──────────────────────────────────────────────────────────────

class _DotsRow extends StatelessWidget {
  final int count;
  final int current;
  const _DotsRow({required this.count, required this.current});

  @override
  Widget build(BuildContext context) {
    // Bei mehr als 20 Dots → nur Zahlen anzeigen
    if (count > 20) {
      return Center(
        child: Text(
          '${current + 1} / $count',
          style: TextStyle(
            color:      Colors.white.withOpacity(0.50),
            fontSize:   13,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(count, (i) {
          final active = i == current;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve:    Curves.easeOut,
            margin:   const EdgeInsets.symmetric(horizontal: 3),
            width:    active ? 18 : 6,
            height:   6,
            decoration: BoxDecoration(
              color:        active
                  ? const Color(0xFF00D4FF)
                  : Colors.white.withOpacity(0.25),
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
// ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final OpSuchtSeasonData season;
  const _EmptyState({required this.season});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.photo_library_outlined,
                color: Colors.white.withOpacity(0.20), size: 52),
            const SizedBox(height: 16),
            Text(
              'Keine OPPASS Bilder verfügbar.',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.55),
                  fontSize: 16,
                  fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Bilder werden aus GitHub geladen.\n'
              'Stelle sicher dass du online bist.',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.35),
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
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  FULLSCREEN GALERIE
// ══════════════════════════════════════════════════════════════

class _FullscreenGallery extends StatefulWidget {
  final List<String> paths;
  final int          initialIndex;

  const _FullscreenGallery({
    required this.paths,
    required this.initialIndex,
  });

  @override
  State<_FullscreenGallery> createState() => _FullscreenGalleryState();
}

class _FullscreenGalleryState extends State<_FullscreenGallery> {
  late int _current;
  late PageController _ctrl;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _ctrl    = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Galerie
          PageView.builder(
            controller:    _ctrl,
            onPageChanged: (i) => setState(() => _current = i),
            itemCount:     widget.paths.length,
            itemBuilder:   (context, i) {
              return InteractiveViewer(
                minScale: 0.8,
                maxScale: 5.0,
                child:    Center(
                  child: Hero(
                    tag: 'oppass_$i',
                    child: Image.file(
                      File(widget.paths[i]),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              );
            },
          ),

          // Schließen-Button
          Positioned(
            top:   MediaQuery.of(context).padding.top + 8,
            right: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:        Colors.black.withOpacity(0.55),
                  shape:        BoxShape.circle,
                  border:       Border.all(
                      color: Colors.white.withOpacity(0.20)),
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 22),
              ),
            ),
          ),

          // Seitenangabe
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 24,
            left:   0, right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color:        Colors.black.withOpacity(0.50),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_current + 1} / ${widget.paths.length}',
                  style: const TextStyle(
                      color:      Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize:   14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
