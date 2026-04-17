import 'package:flutter/material.dart';

import '../config/game_registry.dart';
import '../l10n/app_localizations.dart';
import '../theme/orbit_theme.dart';
import '../widgets/orbit_glass_card.dart';

// ✏️  NEUE IMPORTS für das API-Quest-System:
import 'api_quest_list_screen.dart';  // ← Neuer API-Screen (Fortnite)
import 'task_list_screen.dart';       // ← Alter Screen (BO7 + andere)

// ══════════════════════════════════════════════════════════════
//
//  📋 MODE SELECT SCREEN
//
//  Zeigt alle Spielmodi eines Spiels als Liste an.
//
//  ── NEU: Intelligentes Routing ────────────────────────────
//
//  Je nach Spiel wird der richtige Screen geöffnet:
//
//  ┌──────────────────────────────────────────────────────┐
//  │  Spiel       │ Screen              │ Datenquelle     │
//  ├──────────────┼─────────────────────┼─────────────────┤
//  │  Fortnite    │ ApiQuestListScreen  │ api-fortnite.com │
//  │  BO7         │ TaskListScreen      │ lokale JSON      │
//  │  Andere      │ TaskListScreen      │ lokale JSON      │
//  └──────────────┴─────────────────────┴─────────────────┘
//
//  ✏️  NEUES SPIEL MIT API hinzufügen:
//    → _shouldUseApiScreen() unten anpassen
//
//  ✏️  MODI HINZUFÜGEN / ÄNDERN?
//    → lib/config/game_registry.dart
//
// ══════════════════════════════════════════════════════════════

class ModeSelectScreen extends StatelessWidget {
  /// ID des Spiels (z.B. 'fortnite', 'bo7')
  final String gameId;

  /// Angezeigter Titel in der AppBar
  final String gameTitle;

  const ModeSelectScreen({
    super.key,
    required this.gameId,
    required this.gameTitle,
  });

  // ──────────────────────────────────────────────────────────
  //
  //  🔀 ROUTING-ENTSCHEIDUNG
  //
  //  Gibt true zurück wenn der API-Screen verwendet werden soll.
  //
  //  ✏️  WEITERE SPIELE MIT API: hier zusätzliche IDs eintragen:
  //    case 'valorant':
  //    case 'minecraft':
  //      return true;
  //
  // ──────────────────────────────────────────────────────────

  bool _shouldUseApiScreen(String gameId) {
    switch (gameId) {
      case 'fortnite':
        return true;  // ← Fortnite → API-Screen
      default:
        return false; // ← Alles andere → lokale JSON
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final modes = GameRegistry.modesFor(gameId);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: OrbitBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ───────────────────────────────────
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
                        gameTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Text(
                    l10n.modeSelectSubtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.50),
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                Expanded(
                  child: ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: modes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final mode = modes[i];
                      return _ModeCard(
                        icon:      mode.icon,
                        iconColor: mode.color,
                        title:     mode.title,
                        subtitle:  mode.subtitle,
                        onTap: () => _openMode(context, mode),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  //  Navigation zum richtigen Screen
  // ──────────────────────────────────────────────────────────

  void _openMode(BuildContext context, GameMode mode) {
    Widget screen;

    if (_shouldUseApiScreen(gameId)) {
      // ── API-Screen (Fortnite und andere API-Spiele) ────────
      //
      //  modeId = 'fortnite_br', 'fortnite_og', etc.
      //  Das Format ist: '{gameId}_{modeAssetPath ohne Prefix}'
      //
      //  Beispiele:
      //    assets/data/fortnite_br.json → gameId=fortnite, modeId=fortnite_br
      //    assets/data/fortnite_og.json → gameId=fortnite, modeId=fortnite_og
      //
      final modeId = _extractModeId(mode.assetPath);

      screen = ApiQuestListScreen(
        title:  '$gameTitle – ${mode.title}',
        gameId: gameId,
        modeId: modeId,
      );
    } else {
      // ── Lokaler JSON-Screen (BO7, etc.) ─────────────────────
      screen = TaskListScreen(
        title:         '$gameTitle – ${mode.title}',
        jsonAssetPath: mode.assetPath,
      );
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  // ──────────────────────────────────────────────────────────
  //  Modus-ID aus Asset-Pfad extrahieren
  //
  //  'assets/data/fortnite_br.json'      → 'fortnite_br'
  //  'assets/data/fortnite_kreativ.json' → 'fortnite_kreativ'
  //  'assets/data/bo7_mp.json'           → 'bo7_mp'
  //
  // ──────────────────────────────────────────────────────────

  String _extractModeId(String assetPath) {
    // Dateiname ohne Verzeichnis und Endung
    final fileName = assetPath.split('/').last;       // 'fortnite_br.json'
    return fileName.replaceAll('.json', '');           // 'fortnite_br'
  }
}


// ──────────────────────────────────────────────────────────────
//  _ModeCard — Karte für einen einzelnen Modus
// ──────────────────────────────────────────────────────────────

class _ModeCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ModeCard({
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
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.55),
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                        height: 1.3,
                      ),
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
