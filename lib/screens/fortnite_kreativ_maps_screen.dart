import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../theme/orbit_theme.dart';
import '../widgets/orbit_glass_card.dart';

// ══════════════════════════════════════════════════════════════
// ENUMS
// ══════════════════════════════════════════════════════════════

enum _Recurrence { weeklyOnDay, daily, everyNHours }

// ══════════════════════════════════════════════════════════════
// MODELLE
// ══════════════════════════════════════════════════════════════

// ── Event ──────────────────────────────────────────────────────
//
// ✏️  WO EVENTS HINZUFÜGEN?
//    In der _maps-Liste weiter unten → in events: [ ... ] einfügen.
//
// Recurrence-Typen:
//   _Recurrence.weeklyOnDay  → weekday (1=Mo 2=Di 3=Mi 4=Do 5=Fr 6=Sa 7=So) + hour + minute
//   _Recurrence.daily        → hour + minute (jeden Tag)
//   _Recurrence.everyNHours  → intervalHours (alle X Stunden ab Mitternacht)
//
class _MapEvent {
  final String name;
  final Color color;
  final _Recurrence recurrence;
  final int? weekday; // 1=Mo … 7=So (nur bei weeklyOnDay)
  final int? hour; // Stunde 0-23
  final int? minute; // Minute 0-59 (Standard: 0)
  final int? intervalHours; // Intervall in Stunden (nur bei everyNHours)

  const _MapEvent({
    required this.name,
    required this.color,
    required this.recurrence,
    this.weekday,
    this.hour,
    // ignore: unused_element_parameter
    this.minute = 0,
    this.intervalHours,
  });

  /// Berechnet automatisch den nächsten Zeitpunkt dieses Events
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

// ── Code ───────────────────────────────────────────────────────
//
// ✏️  WO CODES + BESCHREIBUNGEN HINZUFÜGEN?
//    In der _maps-Liste weiter unten → in codes: [ ... ] einfügen.
//
// Felder:
//   label       → Kurzer Name, z. B. "Hauptinsel" oder "Event-Insel"
//   code        → Island-Code, z. B. "1499-6977-1308"
//   description → Was man dort findet/macht (erscheint im Codes-Screen)
//
class _MapCode {
  final String label;
  final String code;
  final String description;

  const _MapCode({
    required this.label,
    required this.code,
    required this.description,
  });
}

// ── Map ────────────────────────────────────────────────────────
//
// ✏️  WO NEUE MAPS HINZUFÜGEN?
//    In der _maps-Liste weiter unten → neuen _KreativMap-Block einfügen.
//
class _KreativMap {
  final String name;
  final String creator;
  final List<_MapCode> codes;
  final List<String> tags;
  final Color accentColor;
  final List<_MapEvent> events;

  const _KreativMap({
    required this.name,
    required this.creator,
    required this.codes,
    required this.tags,
    required this.accentColor,
    this.events = const [],
  });
}

// ══════════════════════════════════════════════════════════════
//
//  ✏️  HIER ALLES BEARBEITEN — MAPS · CODES · EVENTS
//
//  ┌──────────────────────────────────────────────────────────┐
//  │  NEUE MAP hinzufügen:                                    │
//  │    Kopiere einen _KreativMap-Block und füge ihn          │
//  │    VOR dem Kommentar "← NEUE MAP HIER" ein.             │
//  │                                                          │
//  │  NEUEN CODE hinzufügen:                                  │
//  │    In codes: [ ... ] → _MapCode(label:, code:, desc:)    │
//  │                                                          │
//  │  NEUES EVENT hinzufügen:                                 │
//  │    In events: [ ... ] → _MapEvent(name:, color:, ...)    │
//  │                                                          │
//  │  WOCHENTAGE: 1=Mo 2=Di 3=Mi 4=Do 5=Fr 6=Sa 7=So         │
//  └──────────────────────────────────────────────────────────┘
//
// ══════════════════════════════════════════════════════════════

final List<_KreativMap> _maps = [
  // ┌──────────────────────────────────────────────────────────┐
  // │ MAP 1: Klau die Dinos                                    │
  // └──────────────────────────────────────────────────────────┘
  _KreativMap(
    name: 'Klau die Dinos 🦕 [Galaxy-Event 🦅]',
    creator: 'NBRSTUDIOS',
    accentColor: const Color(0xFFFF4444),
    tags: const ['simulator', 'tycoon', 'casual', 'just for fun'],

    // ✏️ CODES – hier bearbeiten oder neue hinzufügen:
    codes: const [
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
      _MapCode(
        label: 'Secret Code',
        code: '0682',
        description: 'Angelic Mammoth',
      ),
      _MapCode(label: 'Secret Code', code: '103961', description: 'Prime rex'),
      _MapCode(
        label: 'Secret Code',
        code: '110452',
        description: 'Raptor Squad',
      ),
      _MapCode(label: 'Secret Code', code: '141516', description: '???'),
      _MapCode(
        label: 'Secret Code',
        code: '150919',
        description: 'Fusion Skip',
      ),
      _MapCode(
        label: 'Secret Code',
        code: '153596',
        description: 'Chocolate Dodo',
      ),
      _MapCode(label: 'Secret Code', code: '197365', description: 'Egg'),
      _MapCode(label: 'Secret Code', code: '2068', description: 'Carno'),
      _MapCode(
        label: 'Secret Code',
        code: '207430',
        description: 'Storm Tapejara',
      ),
      _MapCode(
        label: 'Secret Code',
        code: '237045',
        description: 'Jurassic Egg',
      ),
      _MapCode(label: 'Secret Code', code: '3961', description: 'T- Rex'),
      _MapCode(label: 'Secret Code', code: '593927', description: 'Mammoth'),
      _MapCode(
        label: 'Secret Code',
        code: '596025',
        description: 'Reindeer Spino',
      ),
      _MapCode(
        label: 'Secret Code',
        code: '6525',
        description: 'Infernal Mammoth',
      ),
      _MapCode(
        label: 'Secret Code',
        code: '676767',
        description: 'Fusion Skip',
      ),
      _MapCode(label: 'Secret Code', code: '860912', description: 'Dodo'),
      _MapCode(
        label: 'Secret Code',
        code: '9078',
        description: 'Angelic Indominus',
      ),
      _MapCode(
        label: 'Secret Code',
        code: '929078',
        description: 'Jurassic Egg',
      ),
      _MapCode(
        label: 'Secret Code',
        code: '934062',
        description: 'Random Carno',
      ),
      _MapCode(
        label: 'Secret Code',
        code: '963062',
        description: 'Skeleton Rex',
      ),
      _MapCode(
        label: 'Secret Code',
        code: '967126',
        description: 'Jurassic Egg',
      ),
      // ← Weiteren Code hier einfügen:
      // _MapCode(
      //   label: 'Event-Insel',
      //   code: 'XXXX-XXXX-XXXX',
      //   description: 'Beschreibung was auf dieser Insel passiert...',
      // ),
    ],

    // ✏️ EVENTS – hier bearbeiten oder neue hinzufügen:
    events: const [
      _MapEvent(
        name: '🌌 Galaxy Event',
        color: Color(0xFF00D4FF),
        recurrence: _Recurrence.weeklyOnDay,
        weekday: 7, // Sonntag
        hour: 19,
      ),
      _MapEvent(
        name: '🥚 Lucky Egg Event',
        color: Color(0xFFFFD600),
        recurrence: _Recurrence.everyNHours,
        intervalHours: 9,
      ),
      _MapEvent(
        name: '☠️ Apocalypse Event',
        color: Color(0xFFFF6B35),
        recurrence: _Recurrence.daily,
        hour: 18,
      ),
      _MapEvent(
        name: '💘 Valentine\'s Event',
        color: Color(0xFFFF4081),
        recurrence: _Recurrence.daily,
        hour: 16,
      ),
      _MapEvent(
        name: '🏹 Hunting Night',
        color: Color(0xFF9C6FFF),
        recurrence: _Recurrence.weeklyOnDay,
        weekday: 3, // Mittwoch
        hour: 22,
      ),
      // ← Weiteres Event hier einfügen
    ],
  ),

  // ┌──────────────────────────────────────────────────────────┐
  // │ MAP 2: Monsterklau                                       │
  // └──────────────────────────────────────────────────────────┘
  _KreativMap(
    name: 'Monsterklau 👻 [ADM-ABUSE]',
    creator: 'NBRSTUDIOS',
    accentColor: const Color(0xFF9C6FFF),
    tags: const ['simulator', 'tycoon', 'casual', 'just for fun'],

    // ✏️ CODES:
    codes: const [
      _MapCode(
        label: 'Hauptinsel',
        code: '4262-1024-3421',
        description:
            'Stehlt Monster anderer Spieler! ADM ABUSE-, Upside Down-, '
            'Blood Moon-, Lucky Block-Events – plus Trade System und '
            'Offline-Einnahmen. Schaltet durch Reinkarnationen Perks frei!',
      ),
      // ← Weiteren Code hier einfügen
    ],

    // ✏️ EVENTS:
    events: const [
      _MapEvent(
        name: '👾 ADM ABUSE Event',
        color: Color(0xFF9C6FFF),
        recurrence: _Recurrence.weeklyOnDay,
        weekday: 6, // Samstag
        hour: 19,
      ),
      // ← Weiteres Event hier einfügen
    ],
  ),

  // ← NEUE MAP HIER EINFÜGEN (Vorlage kopieren & anpassen):
  // _KreativMap(
  //   name: 'Map-Name 🗺️',
  //   creator: 'Creator-Name',
  //   accentColor: const Color(0xFF00E676),
  //   tags: const ['tag1', 'tag2'],
  //   codes: const [
  //     _MapCode(
  //       label: 'Hauptinsel',
  //       code: 'XXXX-XXXX-XXXX',
  //       description: 'Was macht man auf dieser Insel?',
  //     ),
  //   ],
  //   events: const [
  //     _MapEvent(
  //       name: '🎉 Event-Name',
  //       color: Color(0xFF00E676),
  //       recurrence: _Recurrence.weeklyOnDay,
  //       weekday: 6, // Samstag
  //       hour: 19,
  //     ),
  //   ],
  // ),
];

// ══════════════════════════════════════════════════════════════
// ÜBERSICHTS-SCREEN
// ══════════════════════════════════════════════════════════════

class FortniteKreativMapsScreen extends StatelessWidget {
  const FortniteKreativMapsScreen({super.key});

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
                            l10n.hubKreativMaps,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                          Text(
                            l10n.hubKreativMapsSubtitle,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.white54,
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
                  itemCount: _maps.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, i) => _MapCard(
                    map: _maps[i],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => _MapDetailScreen(map: _maps[i]),
                      ),
                    ),
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

// ══════════════════════════════════════════════════════════════
// MAP-KARTE (Übersicht)
// ══════════════════════════════════════════════════════════════

class _MapCard extends StatelessWidget {
  final _KreativMap map;
  final VoidCallback onTap;
  const _MapCard({required this.map, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Nächstes Event berechnen
    _MapEvent? nextEvent;
    Duration? nextDur;
    if (map.events.isNotEmpty) {
      nextEvent = map.events.reduce(
        (a, b) => a.timeUntilNext < b.timeUntilNext ? a : b,
      );
      nextDur = nextEvent.timeUntilNext;
    }

    return OrbitGlassCard(
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Farbiger Balken oben
            Container(
              height: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [map.accentColor, map.accentColor.withOpacity(0.3)],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(22),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + Chevron
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          map.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            height: 1.2,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: Colors.white.withOpacity(0.35),
                        size: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Creator
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 13,
                        color: Colors.white.withOpacity(0.45),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        map.creator,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.50),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Erster Code (Vorschau)
                  if (map.codes.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: map.accentColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: map.accentColor.withOpacity(0.35),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.tag, size: 15, color: map.accentColor),
                          const SizedBox(width: 6),
                          Text(
                            map.codes.first.code,
                            style: TextStyle(
                              color: map.accentColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          if (map.codes.length > 1) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: map.accentColor.withOpacity(0.20),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '+${map.codes.length - 1}',
                                style: TextStyle(
                                  color: map.accentColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                  // Nächstes Event (Vorschau)
                  if (nextEvent != null) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: nextEvent.color,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: nextEvent.color.withOpacity(0.6),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            '${nextEvent.name}  ·  in ${_fmtDuration(nextDur!)}',
                            style: TextStyle(
                              color: nextEvent.color,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Tags
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: map.tags
                        .map(
                          (tag) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.07),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.12),
                              ),
                            ),
                            child: Text(
                              tag,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.55),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        )
                        .toList(),
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

// ══════════════════════════════════════════════════════════════
// DETAIL-SCREEN (Hub mit 3 Buttons)
// ══════════════════════════════════════════════════════════════

class _MapDetailScreen extends StatelessWidget {
  final _KreativMap map;
  const _MapDetailScreen({required this.map});

  void _push(BuildContext context, Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    String countdownSubtitle = l10n.comingSoon;
    if (map.events.isNotEmpty) {
      final next = map.events.reduce(
        (a, b) => a.timeUntilNext < b.timeUntilNext ? a : b,
      );
      countdownSubtitle =
          '${next.name}  ·  ${l10n.kreativNextIn} ${_fmtDuration(next.timeUntilNext)}';
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: OrbitBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                      child: Text(
                        map.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.3,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 6),
                  child: Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 13,
                        color: Colors.white.withOpacity(0.45),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        map.creator,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.50),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    children: [
                      _DetailCard(
                        icon: Icons.timer_outlined,
                        iconColor: const Color(0xFF00D4FF),
                        title: l10n.kreativMapCountdowns,
                        subtitle: countdownSubtitle,
                        onTap: map.events.isEmpty
                            ? () => ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(l10n.comingSoon)),
                              )
                            : () => _push(context, _CountdownScreen(map: map)),
                      ),
                      const SizedBox(height: 10),
                      _DetailCard(
                        icon: Icons.tag,
                        iconColor: map.accentColor,
                        title: l10n.kreativMapCodes,
                        subtitle: map.codes.isNotEmpty
                            ? '${map.codes.length} ${l10n.kreativMapCodesCount}'
                            : l10n.comingSoon,
                        onTap: map.codes.isEmpty
                            ? () => ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(l10n.comingSoon)),
                              )
                            : () => _push(context, _CodesScreen(map: map)),
                      ),
                      const SizedBox(height: 10),
                      _DetailCard(
                        icon: Icons.campaign_outlined,
                        iconColor: const Color(0xFF00E676),
                        title: l10n.kreativMapUpdates,
                        subtitle: l10n.comingSoon,
                        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.comingSoon)),
                        ),
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

// ══════════════════════════════════════════════════════════════
// COUNTDOWN-SCREEN (Live-Timer, auto-aktualisierend)
// ══════════════════════════════════════════════════════════════

class _CountdownScreen extends StatefulWidget {
  final _KreativMap map;
  const _CountdownScreen({required this.map});

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
    final sorted = [...widget.map.events]
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
                          Text(
                            widget.map.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
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
                child: widget.map.events.isEmpty
                    ? Center(
                        child: Text(
                          l10n.kreativNoEvents,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.40),
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                        itemCount: sorted.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (context, i) {
                          final event = sorted[i];
                          return _EventCard(
                            event: event,
                            scheduleLabel: event.scheduleLabel(l10n),
                            l10n: l10n,
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
                // Dot
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
                // Countdown-Badge
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
            // Zeitplan
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
            // Nächster Zeitpunkt
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
// CODES-SCREEN
// ══════════════════════════════════════════════════════════════

class _CodesScreen extends StatelessWidget {
  final _KreativMap map;
  const _CodesScreen({required this.map});

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
                          Text(
                            map.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
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
                  itemCount: map.codes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, i) {
                    final mc = map.codes[i];
                    return OrbitGlassCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Label
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

                            // Code (antippen = kopieren)
                            GestureDetector(
                              onTap: () => _copyCode(context, mc.code),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: map.accentColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: map.accentColor.withOpacity(0.40),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.tag,
                                      size: 18,
                                      color: map.accentColor,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        mc.code,
                                        style: TextStyle(
                                          color: map.accentColor,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.copy_rounded,
                                      size: 18,
                                      color: map.accentColor.withOpacity(0.70),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Beschreibung
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

// ══════════════════════════════════════════════════════════════
// DETAIL-KARTE (Hub-Style)
// ══════════════════════════════════════════════════════════════

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
// HILFSFUNKTION
// ══════════════════════════════════════════════════════════════

String _fmtDuration(Duration d) {
  if (d.inSeconds < 60) return '< 1m';
  if (d.inMinutes < 60) return '${d.inMinutes}m';
  final h = d.inHours;
  final m = d.inMinutes - h * 60;
  if (m == 0) return '${h}h';
  return '${h}h ${m}m';
}
