import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'dino_dex_screen.dart';
import 'dino_stats_screen.dart';

import '../theme/orbit_theme.dart';
import '../widgets/orbit_glass_card.dart';
import '../l10n/app_localizations.dart';

// ══════════════════════════════════════════════════════════════
//
//  🦕 DINO MAP DIRECT SCREEN
//  Datei: lib/screens/dino_map_direct_screen.dart
//
//  Öffnet direkt das Detail-Menü der "Klau die Dinos" Map,
//  ohne den Umweg über die Kreativ Maps Übersicht.
//
//  Navigation: Guides Hub → DinoMapDirectScreen (dieser Screen)
//
// ══════════════════════════════════════════════════════════════

// ── Map-Daten (nur Klau die Dinos) ────────────────────────────

enum _Recurrence { weeklyOnDay, daily, everyNHours }

class _MapEvent {
  final String name;
  final Color color;
  final _Recurrence recurrence;
  final int? weekday;
  final int? hour;
  final int? minute;
  final int? intervalHours;

  const _MapEvent({
    required this.name,
    required this.color,
    required this.recurrence,
    this.weekday,
    this.hour,
    this.minute = 0,
    this.intervalHours,
  });

  DateTime get nextOccurrence {
    final now = DateTime.now();
    switch (recurrence) {
      case _Recurrence.weeklyOnDay:
        var d = DateTime(now.year, now.month, now.day, hour!, minute!);
        int diff = (weekday! - now.weekday + 7) % 7;
        if (diff == 0 && !now.isBefore(d)) diff = 7;
        return d.add(Duration(days: diff));
      case _Recurrence.daily:
        var d = DateTime(now.year, now.month, now.day, hour!, minute!);
        if (!now.isBefore(d)) d = d.add(const Duration(days: 1));
        return d;
      case _Recurrence.everyNHours:
        final midnight = DateTime(now.year, now.month, now.day);
        final intervalMs = intervalHours! * 3600000;
        final elapsedMs = now.difference(midnight).inMilliseconds;
        final remaining = intervalMs - (elapsedMs % intervalMs);
        return now.add(Duration(milliseconds: remaining));
    }
  }

  Duration get timeUntilNext => nextOccurrence.difference(DateTime.now());

  String scheduleLabel(AppLocalizations l10n) {
    final t = _fmtTime(hour ?? 0, minute ?? 0);
    switch (recurrence) {
      case _Recurrence.weeklyOnDay:
        return '${l10n.kreativEvery} ${l10n.weekdayNames[weekday! - 1]} · $t';
      case _Recurrence.daily:
        return '${l10n.kreativEveryDay} · $t';
      case _Recurrence.everyNHours:
        return l10n.kreativEveryHours(intervalHours!);
    }
  }

  static String _fmtTime(int h, int m) =>
      '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
}

class _MapCode {
  final String label;
  final String code;
  final String description;

  const _MapCode({
    required this.label,
    required this.code,
    required this.description,
  });

  bool get copyable => !label.toLowerCase().contains('secret');
}

// ── Daten ──────────────────────────────────────────────────────

const _kAccentColor = Color(0xFFFF4444);
const _kCreator = 'NBRSTUDIOS';

const List<_MapCode> _kCodes = [
  _MapCode(
    label: 'Hauptinsel',
    code: '1499-6977-1308',
    description:
        'Stehlt die Dinosaurier anderer Spieler! Kauft und sammelt Dinos '
        'um Gewinne zu erzielen. Schaltet durch Reinkarnationen exklusive '
        'Vorteile frei und baut euer urzeitliches Imperium aus.',
  ),
  _MapCode(label: 'Secret Code', code: '0264', description: 'Raptor Squad'),
  _MapCode(
    label: 'Secret Code',
    code: '034971',
    description: 'Random Jurassic egg',
  ),
  _MapCode(
    label: 'Secret Code',
    code: '049562',
    description: 'Random Reindeerceratops',
  ),
  _MapCode(label: 'Secret Code', code: '0682', description: 'Angelic Mammoth'),
  _MapCode(label: 'Secret Code', code: '103961', description: 'Prime rex'),
  _MapCode(label: 'Secret Code', code: '110452', description: 'Raptor Squad'),
  _MapCode(label: 'Secret Code', code: '141516', description: '???'),
  _MapCode(label: 'Secret Code', code: '150919', description: 'Fusion Skip'),
  _MapCode(label: 'Secret Code', code: '153596', description: 'Chocolate Dodo'),
  _MapCode(label: 'Secret Code', code: '197365', description: 'Egg'),
  _MapCode(label: 'Secret Code', code: '2068', description: 'Carno'),
  _MapCode(label: 'Secret Code', code: '207430', description: 'Storm Tapejara'),
  _MapCode(label: 'Secret Code', code: '237045', description: 'Jurassic Egg'),
  _MapCode(label: 'Secret Code', code: '3961', description: 'T-Rex'),
  _MapCode(label: 'Secret Code', code: '593927', description: 'Mammoth'),
  _MapCode(label: 'Secret Code', code: '596025', description: 'Reindeer Spino'),
  _MapCode(label: 'Secret Code', code: '6525', description: 'Infernal Mammoth'),
  _MapCode(label: 'Secret Code', code: '676767', description: 'Fusion Skip'),
  _MapCode(label: 'Secret Code', code: '860912', description: 'Dodo'),
  _MapCode(
    label: 'Secret Code',
    code: '9078',
    description: 'Angelic Indominus',
  ),
  _MapCode(label: 'Secret Code', code: '929078', description: 'Jurassic Egg'),
  _MapCode(label: 'Secret Code', code: '934062', description: 'Random Carno'),
  _MapCode(label: 'Secret Code', code: '963062', description: 'Skeleton Rex'),
  _MapCode(label: 'Secret Code', code: '967126', description: 'Jurassic Egg'),
];

const List<_MapEvent> _kEvents = [
  _MapEvent(
    name: '🌌 Galaxy Event',
    color: Color(0xFF00D4FF),
    recurrence: _Recurrence.daily,
    hour: 19,
  ),
  _MapEvent(
    name: '🥚 Lucky Egg Event',
    color: Color(0xFFFFD600),
    recurrence: _Recurrence.everyNHours,
    intervalHours: 4,
  ),
  _MapEvent(
    name: '🐇 Easter Event',
    color: Color(0xFFFF6B35),
    recurrence: _Recurrence.weeklyOnDay,
    weekday: 7,
    hour: 18,
  ),
  _MapEvent(
    name: '💘 Valentine\'s Event',
    color: Color(0xFFFF4081),
    recurrence: _Recurrence.daily,
    hour: 21,
  ),
  _MapEvent(
    name: '🏹 Hunting Night',
    color: Color(0xFF9C6FFF),
    recurrence: _Recurrence.weeklyOnDay,
    weekday: 3,
    hour: 23,
  ),
];

// ══════════════════════════════════════════════════════════════
//  SCREEN
// ══════════════════════════════════════════════════════════════

class DinoMapDirectScreen extends StatelessWidget {
  const DinoMapDirectScreen({super.key});

  void _push(BuildContext context, Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    // Nächstes Event berechnen für Countdown-Karte
    final nextEvent = _kEvents.isNotEmpty
        ? _kEvents.reduce((a, b) => a.timeUntilNext < b.timeUntilNext ? a : b)
        : null;

    final countdownSubtitle = nextEvent != null
        ? '${nextEvent.name}  ·  ${l10n.kreativNextIn} ${_fmtDuration(nextEvent.timeUntilNext)}'
        : l10n.comingSoon;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: OrbitBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──────────────────────────────────
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '🦕 Klau die Dinos',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                          Row(
                            children: [
                              Icon(
                                Icons.person_outline,
                                size: 12,
                                color: Colors.white.withOpacity(0.45),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _kCreator,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.50),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    children: [
                      // ── Event-Countdowns ────────────────
                      _DetailCard(
                        icon: Icons.timer_outlined,
                        iconColor: const Color(0xFF00D4FF),
                        title: l10n.kreativMapCountdowns,
                        subtitle: countdownSubtitle,
                        onTap: () => _push(context, const _CountdownScreen()),
                      ),
                      const SizedBox(height: 10),

                      // ── Island-Codes ────────────────────
                      _DetailCard(
                        icon: Icons.tag,
                        iconColor: _kAccentColor,
                        title: l10n.kreativMapCodes,
                        subtitle:
                            '${_kCodes.length} ${l10n.kreativMapCodesCount}',
                        onTap: () => _push(context, const _CodesScreen()),
                      ),
                      const SizedBox(height: 10),

                      // ── Updates ─────────────────────────
                      _DetailCard(
                        icon: Icons.campaign_outlined,
                        iconColor: const Color(0xFF00E676),
                        title: l10n.kreativMapUpdates,
                        subtitle: l10n.comingSoon,
                        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.comingSoon)),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // ── Dino Dex ────────────────────────
                      _DetailCard(
                        icon: Icons.book_outlined,
                        iconColor: const Color(0xFF00E676),
                        title: '🦕 Dino Dex',
                        subtitle: 'Alle Dinos abhaken',
                        onTap: () => _push(context, const DinoDexScreen()),
                      ),
                      const SizedBox(height: 10),

                      // ── Stats ───────────────────────────
                      _DetailCard(
                        icon: Icons.bar_chart,
                        iconColor: const Color(0xFF9C6FFF),
                        title: '📊 Stats',
                        subtitle: 'Fortschritt & Bestenliste',
                        onTap: () => _push(context, const DinoStatsHubScreen()),
                      ),
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

// ──────────────────────────────────────────────────────────────
//  Detail-Karte
// ──────────────────────────────────────────────────────────────

class _DetailCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DetailCard({
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
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: iconColor.withOpacity(0.30),
                    width: 1.2,
                  ),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.55),
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.white.withOpacity(0.35),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  COUNTDOWN SCREEN
// ══════════════════════════════════════════════════════════════

class _CountdownScreen extends StatefulWidget {
  const _CountdownScreen();

  @override
  State<_CountdownScreen> createState() => _CountdownScreenState();
}

class _CountdownScreenState extends State<_CountdownScreen> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sorted = [..._kEvents]
      ..sort((a, b) => a.timeUntilNext.compareTo(b.timeUntilNext));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: OrbitBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.kreativMapCountdowns,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const Text(
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
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  itemCount: sorted.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, i) => _EventCard(
                    event: sorted[i],
                    scheduleLabel: sorted[i].scheduleLabel(l10n),
                    l10n: l10n,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final _MapEvent event;
  final String scheduleLabel;
  final AppLocalizations l10n;

  const _EventCard({
    required this.event,
    required this.scheduleLabel,
    required this.l10n,
  });

  String _fmtDate(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(d.year, d.month, d.day);
    final diff = target.difference(today).inDays;
    if (diff == 0) return l10n.kreativToday;
    if (diff == 1) return l10n.kreativTomorrow;
    return '${l10n.weekdayNames[d.weekday - 1]}, ${d.day}.${d.month}.';
  }

  @override
  Widget build(BuildContext context) {
    final c = event.color;
    final dur = event.timeUntilNext;
    final next = event.nextOccurrence;

    return OrbitGlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: c.withOpacity(0.6), blurRadius: 6),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    event.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: c.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: c.withOpacity(0.40)),
                  ),
                  child: Text(
                    'in ${_fmtDuration(dur)}',
                    style: TextStyle(
                      color: c,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(height: 1, color: Colors.white.withOpacity(0.07)),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.repeat,
                  size: 14,
                  color: Colors.white.withOpacity(0.40),
                ),
                const SizedBox(width: 6),
                Text(
                  scheduleLabel,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.55),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 13,
                  color: Colors.white.withOpacity(0.35),
                ),
                const SizedBox(width: 6),
                Text(
                  '${_fmtDate(next)}  ·  '
                  '${next.hour.toString().padLeft(2, '0')}:'
                  '${next.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.40),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  CODES SCREEN
// ══════════════════════════════════════════════════════════════

class _CodesScreen extends StatelessWidget {
  const _CodesScreen();

  void _copyCode(BuildContext context, String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$code  ✓'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: OrbitBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.kreativMapCodes,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const Text(
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
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  itemCount: _kCodes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, i) {
                    final mc = _kCodes[i];
                    return OrbitGlassCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              mc.label.toUpperCase(),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.45),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 10),
                            mc.copyable
                                ? GestureDetector(
                                    onTap: () => _copyCode(context, mc.code),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _kAccentColor.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: _kAccentColor.withOpacity(
                                            0.40,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.tag,
                                            size: 18,
                                            color: _kAccentColor,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              mc.code,
                                              style: TextStyle(
                                                color: _kAccentColor,
                                                fontSize: 20,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: 1,
                                              ),
                                            ),
                                          ),
                                          Icon(
                                            Icons.copy_rounded,
                                            size: 18,
                                            color: _kAccentColor.withOpacity(
                                              0.70,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.06),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.14),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.tag,
                                          size: 18,
                                          color: Colors.white.withOpacity(0.50),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            mc.code,
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(
                                                0.80,
                                              ),
                                              fontSize: 20,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 1,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                            const SizedBox(height: 12),
                            Text(
                              mc.description,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.70),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (mc.copyable)
                              Text(
                                l10n.kreativMapCodeHint,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.28),
                                  fontSize: 11,
                                ),
                              ),
                          ],
                        ),
                      ),
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
