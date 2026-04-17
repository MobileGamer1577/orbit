import 'package:flutter/material.dart';

import '../config/game_registry.dart';
import '../l10n/app_localizations.dart';
import '../services/in_app_update_service.dart';
import '../services/update_service.dart';
import '../storage/app_settings_store.dart';
import '../storage/collection_store.dart';
import '../storage/update_store.dart';
import '../theme/orbit_theme.dart';
import '../widgets/orbit_glass_card.dart';

// ✏️  Wenn du ein neues Spiel MIT eigenem Hub-Screen hinzufügst,
//     musst du den Import hier ergänzen:
import 'fortnite_hub_screen.dart';
// import 'meinspiel_hub_screen.dart'; // ← Beispiel für neues Spiel
import 'mode_select_screen.dart';
import 'settings_screen.dart';

// ══════════════════════════════════════════════════════════════
//
//  🚀 GAME SELECT SCREEN — Startseite der App
//
//  Zeigt alle Spiele aus GameRegistry als Karten an.
//  Verwaltet die Navigation zu den jeweiligen Spiel-Screens.
//
//  ┌─────────────────────────────────────────────────────────┐
//  │  WIE NAVIGATION IN ORBIT FUNKTIONIERT                   │
//  │                                                         │
//  │  Flutter benutzt einen "Screen-Stapel" (Navigator).     │
//  │  Jeder Navigator.push() legt einen neuen Screen oben    │
//  │  drauf. Der Zurück-Pfeil macht Navigator.pop().         │
//  │                                                         │
//  │  Beispiel:                                              │
//  │  [Startseite] → push → [FortniteHub] → push → [Shop]   │
//  │  [Shop] → pop → [FortniteHub] → pop → [Startseite]     │
//  │                                                         │
//  │  Code für Navigator.push():                             │
//  │  Navigator.push(                                        │
//  │    context,                                             │
//  │    MaterialPageRoute(                                   │
//  │      builder: (_) => MeinScreen(),                      │
//  │    ),                                                   │
//  │  );                                                     │
//  └─────────────────────────────────────────────────────────┘
//
//  ✏️  NEUES SPIEL HINZUFÜGEN:
//
//  Schritt 1: In game_registry.dart eintragen
//             (GameDefinition + GameMode-Liste)
//
//  Schritt 2a — Spiel OHNE Hub (hasCustomHub: false):
//    → Fertig! Keine Änderung hier nötig.
//      Das Spiel erscheint automatisch und öffnet ModeSelectScreen.
//
//  Schritt 2b — Spiel MIT Hub (hasCustomHub: true):
//    → Import oben ergänzen
//    → case in _openGame() unten eintragen
//    → Hub-Screen-Datei erstellen (Anleitung: siehe unten)
//
// ══════════════════════════════════════════════════════════════

class GameSelectScreen extends StatefulWidget {
  final AppSettingsStore settings;
  final UpdateStore updateStore;
  final CollectionStore collection;

  const GameSelectScreen({
    super.key,
    required this.settings,
    required this.updateStore,
    required this.collection,
  });

  @override
  State<GameSelectScreen> createState() => _GameSelectScreenState();
}

class _GameSelectScreenState extends State<GameSelectScreen> {
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _checkUpdates(showNoUpdateToast: false),
    );
  }

  // ──────────────────────────────────────────────────────────
  //
  //  🧭 NAVIGATION — öffnet den richtigen Screen pro Spiel
  //
  //  Spiel OHNE Hub (hasCustomHub: false):
  //    → Läuft automatisch, kein case nötig
  //
  //  Spiel MIT Hub (hasCustomHub: true):
  //    → Neuen case hier eintragen
  //
  //  ✏️  NEUES SPIEL MIT HUB — So geht's:
  //  ┌───────────────────────────────────────────────────────┐
  //  │  case 'meinspiel':                                    │
  //  │    Navigator.push(                                    │
  //  │      context,                                         │
  //  │      MaterialPageRoute(                               │
  //  │        builder: (_) => MeinSpielHubScreen(            │
  //  │          settings: widget.settings,    // Einstellungen│
  //  │          collection: widget.collection, // Spind-Daten │
  //  │        ),                                             │
  //  │      ),                                               │
  //  │    );                                                 │
  //  │    return;                                            │
  //  └───────────────────────────────────────────────────────┘
  //
  //  ⚠️  widget.settings und widget.collection sind die
  //      App-weiten Stores. Übergib sie immer weiter, wenn
  //      dein Hub-Screen sie braucht (z.B. für Spind/Wishlist).
  //
  // ──────────────────────────────────────────────────────────

  void _openGame(GameDefinition game) {
    // Spiel ohne eigenen Hub → direkt zur Modus-Auswahl
    if (!game.hasCustomHub) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ModeSelectScreen(
            gameId: game.id,
            gameTitle: game.title,
          ),
        ),
      );
      return;
    }

    // Spiel mit eigenem Hub → spezifische Navigation
    // ✏️  HIER neuen case eintragen für Spiele mit Hub:
    switch (game.id) {

      case 'fortnite':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FortniteHubScreen(
              settings: widget.settings,
              collection: widget.collection,
            ),
          ),
        );
        return;

      // ✏️  Neues Spiel mit Hub — Vorlage:
      // case 'minecraft':
      //   Navigator.push(
      //     context,
      //     MaterialPageRoute(
      //       builder: (_) => MinecraftHubScreen(
      //         settings: widget.settings,
      //         collection: widget.collection,
      //       ),
      //     ),
      //   );
      //   return;

    }

    // Sicherheitsnetz: Hub eingetragen aber kein case → zu Modi
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ModeSelectScreen(
          gameId: game.id,
          gameTitle: game.title,
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  //  Update-Logik — nicht ändern
  // ──────────────────────────────────────────────────────────

  Future<void> _checkUpdates({required bool showNoUpdateToast}) async {
    if (_checking) return;
    setState(() => _checking = true);
    try {
      final result = await UpdateService.checkForUpdates();
      if (!mounted) return;
      final l10n = context.l10n;
      if (result.updateAvailable) {
        await _showUpdateDialog(
          version: result.latest,
          notes: result.notes ?? '',
          url: result.releaseUrl,
        );
      } else {
        if (showNoUpdateToast) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.updateNoUpdate)),
          );
        }
      }
    } catch (_) {
      if (showNoUpdateToast && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.updateFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _showUpdateDialog({
    required String version,
    required String notes,
    required String url,
  }) async {
    final l10n = context.l10n;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.updateAvailableTitle(version)),
        content: SingleChildScrollView(
          child: Text(notes.isEmpty ? l10n.updateDialogNotes : notes),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.updateDialogLater),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await InAppUpdateService.downloadAndInstallApk(apkUrl: url);
            },
            child: Text(l10n.updateDialogOpen),
          ),
        ],
      ),
    );
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SettingsScreen(
          settings: widget.settings,
          updateStore: widget.updateStore,
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  //  UI Build
  // ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      body: OrbitBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF9C6FFF).withOpacity(0.35),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Icon(
                        Icons.public,
                        color: Colors.white.withOpacity(0.95),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Orbit',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _openSettings,
                      icon: Icon(
                        Icons.settings_outlined,
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),
                Text(
                  l10n.gameSelectSubtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.55),
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 20),

                // Spiele-Karten aus Registry — automatisch generiert
                ...GameRegistry.games.map((game) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _GameCard(
                    title: game.title,
                    subtitle: game.subtitle,
                    accentColor: game.accentColor,
                    secondaryColor: game.secondaryColor,
                    icon: game.icon,
                    onTap: () => _openGame(game),
                  ),
                )),

                const Spacer(),

                // Update Button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _checking
                        ? null
                        : () => _checkUpdates(showNoUpdateToast: true),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.10),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: Colors.white.withOpacity(0.12),
                        ),
                      ),
                    ),
                    icon: Icon(
                      _checking ? Icons.hourglass_top : Icons.system_update_alt,
                      size: 18,
                    ),
                    label: Text(
                      _checking ? l10n.updateChecking2 : l10n.updateCheckButton,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
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
//  _GameCard — Karte für ein Spiel auf dem Startscreen
//  Daten kommen aus GameRegistry — hier nichts ändern.
// ──────────────────────────────────────────────────────────────

class _GameCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color accentColor;
  final Color secondaryColor;
  final IconData icon;
  final VoidCallback onTap;

  const _GameCard({
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.secondaryColor,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OrbitGlassCard(
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accentColor.withOpacity(0.28),
                      secondaryColor.withOpacity(0.18),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: accentColor.withOpacity(0.35),
                    width: 1.2,
                  ),
                ),
                child: Icon(icon, color: accentColor, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.60),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: Colors.white.withOpacity(0.45),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
