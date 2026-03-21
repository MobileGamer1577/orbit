import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/orbit_theme.dart';
import '../widgets/orbit_glass_card.dart';

// ──────────────────────────────────────────────────────────────
// Datenmodell
// ──────────────────────────────────────────────────────────────

class _KreativMap {
  final String name;
  final String creator;
  final String islandCode;
  final String description;
  final List<String> tags;
  final Color accentColor;

  const _KreativMap({
    required this.name,
    required this.creator,
    required this.islandCode,
    required this.description,
    required this.tags,
    required this.accentColor,
  });
}

// ──────────────────────────────────────────────────────────────
// Map-Daten
// ──────────────────────────────────────────────────────────────

final List<_KreativMap> _maps = [
  const _KreativMap(
    name: 'Klau die Dinos 🦕 [Galaxy-Event 🦅]',
    creator: 'NBRSTUDIOS',
    islandCode: '1499-6977-1308',
    description:
        'Macht euch bereit für ein episches Abenteuer, in dem ihr die Dinosaurier anderer Spieler stehlt, um eure eigene urzeitliche Sammlung aufzubauen! Kauft Dinosaurier, um Gewinne zu erzielen und exklusive Vorteile durch Reinkarnationen freizuschalten. Sammelt seltene Dinosaurier und seht zu, wie euer urzeitliches Imperium wächst!',
    tags: ['simulator', 'tycoon', 'casual', 'just for fun'],
    accentColor: Color(0xFFFF4444),
  ),
  const _KreativMap(
    name: 'Monsterklau 👻 [ADM-ABUSE]',
    creator: 'NBRSTUDIOS',
    islandCode: '4262-1024-3421',
    description:
        'ADM ABUSE EVENT! • UPSIDE DOWN EVENT! • BLOOD MOON EVENT! • LUCKY BLOCK EVENT! • TRADE SYSTEM! • EARN CASH OFFLINE! • REBIRTH TO GAIN POWERFUL PERKS!',
    tags: ['simulator', 'tycoon', 'casual', 'just for fun'],
    accentColor: Color(0xFF9C6FFF),
  ),
];

// ──────────────────────────────────────────────────────────────
// Screen
// ──────────────────────────────────────────────────────────────

class FortniteKreativMapsScreen extends StatelessWidget {
  const FortniteKreativMapsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: OrbitBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ───────────────────────────────────
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
                            'Kreativ Maps',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                          Text(
                            'Fortnite Creative Inseln',
                            style: TextStyle(
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

              // ── Map-Liste ─────────────────────────────────
              Expanded(
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  itemCount: _maps.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, i) => _MapCard(map: _maps[i]),
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
// Map-Karte
// ──────────────────────────────────────────────────────────────

class _MapCard extends StatelessWidget {
  final _KreativMap map;

  const _MapCard({required this.map});

  void _copyCode(BuildContext context) {
    Clipboard.setData(ClipboardData(text: map.islandCode));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Code kopiert: ${map.islandCode}'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OrbitGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Farbiger Balken oben ──────────────────────
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
                // ── Name + Creator ────────────────────────
                Text(
                  map.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
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

                // ── Island Code ───────────────────────────
                GestureDetector(
                  onTap: () => _copyCode(context),
                  child: Container(
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
                          map.islandCode,
                          style: TextStyle(
                            color: map.accentColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.copy_rounded,
                          size: 14,
                          color: map.accentColor.withOpacity(0.70),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ── Beschreibung ──────────────────────────
                Text(
                  map.description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.60),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.45,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 12),

                // ── Tags ──────────────────────────────────
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
    );
  }
}
