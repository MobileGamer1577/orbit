import 'package:flutter/material.dart';

import '../config/game_registry.dart';
import '../l10n/app_localizations.dart';
import '../theme/orbit_theme.dart';
import '../widgets/orbit_glass_card.dart';
import 'mode_select_screen.dart';

// ══════════════════════════════════════════════════════════════
//
//  🛠 DEV SCREEN — Interner Entwicklerbereich
//
//  Dieser Screen ist für normale Nutzer NICHT sichtbar.
//  Zugang: 5-7x schnell auf die Versionsnummer in den
//  Einstellungen tippen (wie Android Developer Options).
//
//  ✏️  HIER KANNST DU TEST-BUTTONS EINTRAGEN:
//      → _DevButton unten kopieren und anpassen
//
// ══════════════════════════════════════════════════════════════

class DevScreen extends StatefulWidget {
  const DevScreen({super.key});

  @override
  State<DevScreen> createState() => _DevScreenState();
}

class _DevScreenState extends State<DevScreen> {

  // ── Hilfsmethode: Screen öffnen ───────────────────────────
  void _push(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  // ── Hilfsmethode: SnackBar anzeigen ──────────────────────
  void _toast(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: OrbitBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Header ─────────────────────────────────
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const SizedBox(width: 6),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '🛠 DEV MODE',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                          Text(
                            'Interner Entwicklerbereich',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF9C6FFF),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // ── Warnung-Banner ─────────────────────────
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B35).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFFF6B35).withOpacity(0.40),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Color(0xFFFF6B35),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Nur für interne Tests. Nichts hier ist für normale Nutzer sichtbar.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.80),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Test-Buttons ───────────────────────────
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    children: [

                      // ── Sektion: Navigation testen ───────
                      _SectionLabel('Navigation testen'),
                      const SizedBox(height: 8),

                      _DevButton(
                        icon: Icons.sports_esports,
                        label: 'TEST GAME öffnen',
                        subtitle: 'ModeSelectScreen mit testgame',
                        color: const Color(0xFF00E676),
                        onTap: () {
                          // Öffnet den Test-Modus aus der Registry
                          // (testgame muss in game_registry.dart vorhanden sein)
                          _push(const ModeSelectScreen(
                            gameId: 'testgame',
                            gameTitle: 'TEST GAME',
                          ));
                        },
                      ),
                      const SizedBox(height: 10),

                      _DevButton(
                        icon: Icons.gamepad,
                        label: 'Alle Fortnite-Modi',
                        subtitle: 'ModeSelectScreen mit fortnite',
                        color: const Color(0xFF00D4FF),
                        onTap: () => _push(const ModeSelectScreen(
                          gameId: 'fortnite',
                          gameTitle: 'Fortnite',
                        )),
                      ),
                      const SizedBox(height: 10),

                      _DevButton(
                        icon: Icons.military_tech,
                        label: 'Alle BO7-Modi',
                        subtitle: 'ModeSelectScreen mit bo7',
                        color: const Color(0xFFFF6B35),
                        onTap: () => _push(const ModeSelectScreen(
                          gameId: 'bo7',
                          gameTitle: 'BO7',
                        )),
                      ),

                      // ── Sektion: Registry-Info ────────────
                      const SizedBox(height: 24),
                      _SectionLabel('GameRegistry — aktuelle Daten'),
                      const SizedBox(height: 8),

                      _DevButton(
                        icon: Icons.list_alt,
                        label: 'Registry ausgeben',
                        subtitle: 'Zeigt alle Spiele + Modus-Anzahl',
                        color: const Color(0xFFFFD600),
                        onTap: () {
                          final info = GameRegistry.games.map((g) {
                            return '${g.id}: ${g.modes.length} Modi'
                                '${g.hasCustomHub ? ' [Hub]' : ''}';
                          }).join('\n');
                          _toast(info);
                        },
                      ),

                      // ── Sektion: UI testen ────────────────
                      const SizedBox(height: 24),
                      _SectionLabel('UI & Komponenten'),
                      const SizedBox(height: 8),

                      _DevButton(
                        icon: Icons.notifications,
                        label: 'Test-SnackBar',
                        subtitle: 'Einfache Meldung anzeigen',
                        color: const Color(0xFF9C6FFF),
                        onTap: () => _toast('🛠 DEV: SnackBar funktioniert!'),
                      ),
                      const SizedBox(height: 10),

                      _DevButton(
                        icon: Icons.dialpad,
                        label: 'Test-Dialog',
                        subtitle: 'AlertDialog anzeigen',
                        color: const Color(0xFFFF81E0),
                        onTap: () => showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('DEV Dialog'),
                            content: const Text('Dialog funktioniert korrekt.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ══════════════════════════════════════
                      // ✏️  WEITERE TEST-BUTTONS HIER EINFÜGEN:
                      //
                      // const SizedBox(height: 10),
                      // _DevButton(
                      //   icon: Icons.bug_report,
                      //   label: 'Mein Test',
                      //   subtitle: 'Was dieser Button macht',
                      //   color: const Color(0xFFFF4444),
                      //   onTap: () {
                      //     // Dein Test-Code hier
                      //   },
                      // ),
                      // ══════════════════════════════════════

                      const SizedBox(height: 32),
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
//  _DevButton — Ein Test-Button im Dev Screen
// ──────────────────────────────────────────────────────────────

class _DevButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _DevButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OrbitGlassCard(
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: color.withOpacity(0.40), width: 1.2),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.50),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.white.withOpacity(0.30),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// ──────────────────────────────────────────────────────────────
//  _SectionLabel — Überschrift für eine Gruppe von Buttons
// ──────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        color: Colors.white.withOpacity(0.38),
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.4,
      ),
    );
  }
}
