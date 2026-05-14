import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../storage/app_settings_store.dart';
import '../theme/orbit_theme.dart';
import '../widgets/orbit_glass_card.dart';

// ══════════════════════════════════════════════════════════════
//
//  🤖 DROID TYCOON SCREEN
//  Datei: lib/screens/droid_tycoon_screen.dart
//
//  Rebirth-Guide für "Star Wars Droid Tycoon".
//  Rainbow-Droids haben eine animierte HSV-Farbanimation —
//  steuerbar über Einstellungen → Animationen → Rainbow.
//
//  ✏️  DATEN AKTUALISIEREN:
//    → _kRebirths Liste unten anpassen
//
// ══════════════════════════════════════════════════════════════

// ── Rarity-Farben ──────────────────────────────────────────────

const Map<String, Color> _rarityColors = {
  'basic': Color(0xFF8F8F8F),
  'gold': Color(0xFFFFD700),
  'diamond': Color(0xFF00E5FF),
  'rainbow': Color(0xFFFFFFFF),
};

const Map<String, String> _rarityLabels = {
  'basic': 'Basic',
  'gold': 'Gold',
  'diamond': 'Diamond',
  'rainbow': 'Rainbow',
};

// ── Datenmodell ────────────────────────────────────────────────

class _Droid {
  final String name;
  final String rarity;
  const _Droid(this.name, this.rarity);
}

class _Rebirth {
  final int level;
  final String credits;
  final List<_Droid> droids;
  const _Rebirth({
    required this.level,
    required this.credits,
    required this.droids,
  });
}

// ── Rebirth-Daten ──────────────────────────────────────────────
//
// ✏️  HIER anpassen wenn sich das Spiel ändert.
//
const List<_Rebirth> _kRebirths = [
  _Rebirth(
    level: 1,
    credits: '10.000',
    droids: [
      _Droid('CB', 'basic'),
      _Droid('Pit', 'basic'),
      _Droid('DRK-1 Probe', 'basic'),
    ],
  ),
  _Rebirth(
    level: 2,
    credits: '150.000',
    droids: [
      _Droid('BDX Explorer', 'basic'),
      _Droid('2BB', 'basic'),
      _Droid('Bal-Core', 'basic'),
    ],
  ),
  _Rebirth(
    level: 3,
    credits: '975.000',
    droids: [
      _Droid('A-LT', 'basic'),
      _Droid('BU-4D', 'basic'),
      _Droid('R9', 'gold'),
    ],
  ),
  _Rebirth(
    level: 4,
    credits: '2,95 Mio.',
    droids: [
      _Droid('ARG', 'gold'),
      _Droid('B1 Security', 'gold'),
      _Droid('Groundmech', 'basic'),
    ],
  ),
  _Rebirth(
    level: 5,
    credits: '5,35 Mio.',
    droids: [
      _Droid('BU-4D', 'gold'),
      _Droid('HOV-R', 'gold'),
      _Droid('R9', 'diamond'),
    ],
  ),
  _Rebirth(
    level: 6,
    credits: '9,85 Mio.',
    droids: [
      _Droid('Groundmech', 'gold'),
      _Droid('ARG', 'diamond'),
      _Droid('A-LT', 'diamond'),
    ],
  ),
  _Rebirth(
    level: 7,
    credits: '14,5 Mio.',
    droids: [
      _Droid('BB', 'gold'),
      _Droid('B1 Security', 'diamond'),
      _Droid('BU-4D', 'diamond'),
    ],
  ),
  _Rebirth(
    level: 8,
    credits: '36 Mio.',
    droids: [
      _Droid('UTIL-TEC', 'gold'),
      _Droid('LO', 'gold'),
      _Droid('HOV-R', 'diamond'),
    ],
  ),
  _Rebirth(
    level: 9,
    credits: '89 Mio.',
    droids: [
      _Droid('Groundmech', 'rainbow'),
      _Droid('R6', 'gold'),
      _Droid('TRAK-R', 'gold'),
    ],
  ),
  _Rebirth(
    level: 10,
    credits: '220 Mio.',
    droids: [
      _Droid('LO', 'rainbow'),
      _Droid('HAUL-R', 'rainbow'),
      _Droid('Strike-Orb', 'gold'),
    ],
  ),
  _Rebirth(
    level: 11,
    credits: '550 Mio.',
    droids: [
      _Droid('AMP Walker', 'rainbow'),
      _Droid('B1 Heavy', 'rainbow'),
      _Droid('BB9', 'gold'),
    ],
  ),
  _Rebirth(
    level: 12,
    credits: '1,36 Mrd.',
    droids: [
      _Droid('Proto-Roller', 'rainbow'),
      _Droid('Mecha-Droid', 'diamond'),
      _Droid('MONO-WLKR', 'gold'),
    ],
  ),
  _Rebirth(
    level: 13,
    credits: '3,40 Mrd.',
    droids: [
      _Droid('R7', 'rainbow'),
      _Droid('Cyclo-Grav', 'rainbow'),
      _Droid('B2-RP', 'rainbow'),
    ],
  ),
  _Rebirth(
    level: 14,
    credits: '8,45 Mrd.',
    droids: [
      _Droid('Opti-STRK', 'rainbow'),
      _Droid('MONO-WLKR', 'rainbow'),
      _Droid('Mecha-Droid', 'rainbow'),
    ],
  ),
  _Rebirth(
    level: 15,
    credits: '21 Mrd.',
    droids: [
      _Droid('R7', 'rainbow'),
      _Droid('Cyclo-Grav', 'rainbow'),
      _Droid('B2-RP', 'rainbow'),
    ],
  ),
  _Rebirth(
    level: 16,
    credits: '52 Mrd.',
    droids: [
      _Droid('Opti-STRK', 'rainbow'),
      _Droid('Mono-WLKR', 'rainbow'),
      _Droid('Proto-Roller', 'rainbow'),
    ],
  ),
  _Rebirth(
    level: 17,
    credits: '130 Mrd.',
    droids: [
      _Droid('B2-RP', 'rainbow'),
      _Droid('Cyclo-Grav', 'rainbow'),
      _Droid('Mecha-Droid', 'rainbow'),
    ],
  ),
];

// ══════════════════════════════════════════════════════════════
//  SCREEN
// ══════════════════════════════════════════════════════════════

class DroidTycoonScreen extends StatelessWidget {
  const DroidTycoonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // animRainbow einmalig hier lesen — wird an Kindwidgets weitergegeben
    final animRainbow = context.watch<AppSettingsStore>().animRainbow;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: OrbitBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────
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
                          const Text(
                            '🤖 Droid Tycoon',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                          Text(
                            'Star Wars Droid Tycoon · Rebirth Guide',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.50),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Legende ─────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                child: Row(
                  children: [
                    _LegendDot(color: _rarityColors['basic']!, label: 'Basic'),
                    const SizedBox(width: 12),
                    _LegendDot(color: _rarityColors['gold']!, label: 'Gold'),
                    const SizedBox(width: 12),
                    _LegendDot(
                      color: _rarityColors['diamond']!,
                      label: 'Diamond',
                    ),
                    const SizedBox(width: 12),
                    // Legende-Dot: animiert wenn an, statisch wenn aus
                    animRainbow
                        ? const _RainbowLegendDot()
                        : _LegendDot(
                            color: const Color(0xFF9C6FFF),
                            label: 'Rainbow',
                          ),
                  ],
                ),
              ),

              const SizedBox(height: 6),

              // ── Liste ───────────────────────────────────
              Expanded(
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                  itemCount: _kRebirths.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) => _RebirthCard(
                    rebirth: _kRebirths[i],
                    animRainbow: animRainbow,
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

// ──────────────────────────────────────────────────────────────
//  Legende
// ──────────────────────────────────────────────────────────────

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.55),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _RainbowLegendDot extends StatefulWidget {
  const _RainbowLegendDot();
  @override
  State<_RainbowLegendDot> createState() => _RainbowLegendDotState();
}

class _RainbowLegendDotState extends State<_RainbowLegendDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            final color = HSVColor.fromAHSV(
              1.0,
              _ctrl.value * 360,
              1.0,
              1.0,
            ).toColor();
            return Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            );
          },
        ),
        const SizedBox(width: 5),
        Text(
          'Rainbow',
          style: TextStyle(
            color: Colors.white.withOpacity(0.55),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  Rebirth-Karte
// ──────────────────────────────────────────────────────────────

class _RebirthCard extends StatelessWidget {
  final _Rebirth rebirth;
  final bool animRainbow;

  const _RebirthCard({required this.rebirth, required this.animRainbow});

  @override
  Widget build(BuildContext context) {
    const rarityPriority = ['rainbow', 'diamond', 'gold', 'basic'];
    final topRarity = rarityPriority.firstWhere(
      (r) => rebirth.droids.any((d) => d.rarity == r),
      orElse: () => 'basic',
    );

    final accentColor = topRarity == 'rainbow'
        ? const Color(0xFF9C6FFF)
        : (_rarityColors[topRarity] ?? const Color(0xFF8F8F8F));

    return OrbitGlassCard(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rebirth-Nummer
            Container(
              width: 52,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accentColor.withOpacity(0.40)),
              ),
              child: Column(
                children: [
                  Text(
                    '${rebirth.level}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      height: 1.0,
                    ),
                  ),
                  Text(
                    'RB',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: accentColor.withOpacity(0.65),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),

            // Credits + Droids
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.monetization_on_outlined,
                        size: 14,
                        color: const Color(0xFFFFD700).withOpacity(0.80),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${rebirth.credits} Credits',
                        style: const TextStyle(
                          color: Color(0xFFFFD700),
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: rebirth.droids
                        .map(
                          (d) => _DroidChip(droid: d, animRainbow: animRainbow),
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

// ──────────────────────────────────────────────────────────────
//  Droid-Chip
// ──────────────────────────────────────────────────────────────

class _DroidChip extends StatelessWidget {
  final _Droid droid;
  final bool animRainbow;

  const _DroidChip({required this.droid, required this.animRainbow});

  @override
  Widget build(BuildContext context) {
    if (droid.rarity == 'rainbow') {
      // Animation an → bunter Chip, aus → statischer lila Chip
      return animRainbow
          ? _RainbowDroidChip(name: droid.name)
          : _StaticRainbowChip(name: droid.name);
    }

    final color = _rarityColors[droid.rarity] ?? const Color(0xFF8F8F8F);
    final label = _rarityLabels[droid.rarity] ?? droid.rarity;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.40)),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: droid.name,
              style: TextStyle(
                color: Colors.white.withOpacity(0.90),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            TextSpan(
              text: ' ($label)',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Statischer Rainbow-Chip (Animation aus)
class _StaticRainbowChip extends StatelessWidget {
  final String name;
  const _StaticRainbowChip({required this.name});

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF9C6FFF); // Lila als statische Farbe
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.40)),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: name,
              style: TextStyle(
                color: Colors.white.withOpacity(0.90),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            const TextSpan(
              text: ' (Rainbow)',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Animierter Rainbow-Chip
class _RainbowDroidChip extends StatefulWidget {
  final String name;
  const _RainbowDroidChip({required this.name});

  @override
  State<_RainbowDroidChip> createState() => _RainbowDroidChipState();
}

class _RainbowDroidChipState extends State<_RainbowDroidChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) {
          final color = HSVColor.fromAHSV(
            1.0,
            _ctrl.value * 360,
            0.85,
            1.0,
          ).toColor();
          final color2 = HSVColor.fromAHSV(
            1.0,
            (_ctrl.value * 360 + 60) % 360,
            0.85,
            1.0,
          ).toColor();

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.18), color2.withOpacity(0.10)],
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withOpacity(0.60)),
            ),
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: widget.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  TextSpan(
                    text: ' (Rainbow)',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
