import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/orbit_theme.dart';
import '../widgets/orbit_glass_card.dart';

// ── Imports für die drei Unterbereiche ──────────────────────────
import 'fortnite_kreativ_maps_screen.dart'; // Steal the Dino Map (bestehend)
import 'fortnite_brainrot_codes_screen.dart'; // NEU: Brainrot Codes
import 'fortnite_xp_calculator_screen.dart'; // NEU: XP Taschenrechner

// ══════════════════════════════════════════════════════════════
//
//  🗺  GUIDES HUB SCREEN
//  Datei: lib/screens/fortnite_guides_hub_screen.dart
//
//  Drehscheibe für alle Guide-Inhalte:
//    • Steal the Dino Map  → FortniteKreativMapsScreen (bestehend)
//    • Brainrot Codes      → FortniteBrainrotCodesScreen (NEU)
//    • XP Taschenrechner   → FortniteXpCalculatorScreen (NEU)
//
//  ✏️  NEUEN GUIDE HINZUFÜGEN:
//    1. Neuen Screen erstellen
//    2. Import oben ergänzen
//    3. Neuen _GuideCard-Block in build() einfügen
//
//  CHANGELOG:
//    - Erstellt als Ersatz für den direkten "Kreativ Maps"-Button
//      im FortniteHubScreen (der nun "Guides" heißt)
//    - Monsterklau wurde aus FortniteKreativMapsScreen entfernt
//
// ══════════════════════════════════════════════════════════════

class FortniteGuidesHubScreen extends StatelessWidget {
  const FortniteGuidesHubScreen({super.key});

  void _push(BuildContext context, Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

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
                      child: Text(
                        l10n.hubGuides,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 16),
                  child: Text(
                    l10n.guidesWhatOpen,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.50),
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),

                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    children: [
                      // ── A) Steal the Dino Map ────────────
                      // Öffnet FortniteKreativMapsScreen (Monsterklau entfernt,
                      // nur noch "Klau die Dinos" mit Codes / Events / Dino Dex)
                      _GuideCard(
                        icon: Icons.map_outlined,
                        iconColor: const Color(0xFF00E676),
                        title: l10n.guidesStealTheDino,
                        subtitle: l10n.guidesStealTheDinoSubtitle,
                        onTap: () =>
                            _push(context, const FortniteKreativMapsScreen()),
                      ),
                      const SizedBox(height: 12),

                      // ── B) Brainrot Codes ─────────────────
                      // NEU: Island-Code + Liste abhakbarer Codes
                      _GuideCard(
                        icon: Icons.vpn_key_outlined,
                        iconColor: const Color(0xFFFF8C00),
                        title: l10n.guidesBrainrotCodes,
                        subtitle: l10n.guidesBrainrotCodesSubtitle,
                        onTap: () =>
                            _push(context, const FortniteBrainrotCodesScreen()),
                      ),
                      const SizedBox(height: 12),

                      // ── C) XP Taschenrechner ─────────────
                      // NEU: Season-Fortschritt + Level-Rechner + Spielzeit-XP
                      _GuideCard(
                        icon: Icons.calculate_outlined,
                        iconColor: const Color(0xFF9C6FFF),
                        title: l10n.guidesXpCalc,
                        subtitle: l10n.guidesXpCalcSubtitle,
                        onTap: () =>
                            _push(context, const FortniteXpCalculatorScreen()),
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
//  _GuideCard — Einheitliche Karte für jeden Guide-Eintrag
// ──────────────────────────────────────────────────────────────

class _GuideCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _GuideCard({
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
              // Icon-Container
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: iconColor.withOpacity(0.35),
                    width: 1.2,
                  ),
                ),
                child: Icon(icon, color: iconColor, size: 26),
              ),
              const SizedBox(width: 16),

              // Titel + Untertitel
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.55),
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.40)),
            ],
          ),
        ),
      ),
    );
  }
}
