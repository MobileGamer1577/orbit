import 'package:flutter/material.dart';

import '../theme/orbit_theme.dart';
import '../storage/app_settings_store.dart';
import '../storage/update_store.dart';
import 'mode_select_screen.dart';
import 'fortnite_hub_screen.dart';
import 'settings_screen.dart';

class GameSelectScreen extends StatefulWidget {
  final AppSettingsStore settings;
  final UpdateStore updateStore;

  const GameSelectScreen({
    super.key,
    required this.settings,
    required this.updateStore,
  });

  @override
  State<GameSelectScreen> createState() => _GameSelectScreenState();
}

class _GameSelectScreenState extends State<GameSelectScreen> {
  @override
  void initState() {
    super.initState();

    // Popup nach dem ersten Frame (damit context safe ist)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Wenn Check noch nicht gelaufen ist: kurz warten/auslösen
      // (bei dir wird updateStore.check() schon in main() gestartet)
      if (widget.updateStore.shouldShowPopup) {
        await _showUpdateDialog();
      }
    });

    // Wenn UpdateStore später erst "updateAvailable=true" bekommt,
    // wollen wir ebenfalls einmal poppen:
    widget.updateStore.addListener(_maybeShowPopupOnUpdate);
  }

  @override
  void dispose() {
    widget.updateStore.removeListener(_maybeShowPopupOnUpdate);
    super.dispose();
  }

  Future<void> _maybeShowPopupOnUpdate() async {
    if (!mounted) return;
    if (widget.updateStore.shouldShowPopup) {
      await _showUpdateDialog();
    }
  }

  Future<void> _showUpdateDialog() async {
    widget.updateStore.markPopupShown();

    final notes = (widget.updateStore.notes ?? '').trim();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update verfügbar ✅'),
        content: Text(
          'Aktuell: ${widget.updateStore.current}\n'
          'Neu: ${widget.updateStore.latest}'
          '${notes.isNotEmpty ? '\n\n' + notes : ''}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Später'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);

              // optional: kleiner Loader
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Update wird geladen…')),
              );

              try {
                await widget.updateStore.downloadAndInstall();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Update fehlgeschlagen: $e')),
                );
              }
            },
            child: const Text('Jetzt installieren'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasUpdate = widget.updateStore.updateAvailable;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: OrbitBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),

                // Header + Settings Button rechts
                Row(
                  children: [
                    const Icon(Icons.public, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Orbit',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),

                    // Mini "Update Punkt" am Settings Icon, wenn Update da ist
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IconButton(
                          tooltip: 'Einstellungen',
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SettingsScreen(settings: widget.settings),
                            ),
                          ),
                          icon: const Icon(Icons.settings),
                        ),
                        if (hasUpdate)
                          Positioned(
                            right: 10,
                            top: 10,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: Colors.greenAccent.withOpacity(0.95),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 14),
                Text(
                  'Wähle ein Spiel',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white70,
                      ),
                ),
                const SizedBox(height: 16),

                Expanded(
                  child: ListView(
                    children: [
                      _GameCard(
                        title: 'Fortnite',
                        subtitle: 'Aufgaben abhaken • Season-Countdown • Item-Shop (bald)',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const FortniteHubScreen()),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _GameCard(
                        title: 'Call of Duty: Black Ops 7',
                        subtitle: 'Aufgaben (Soon) • Steam Erfolge • Countdowns (Soon)',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ModeSelectScreen(
                              gameId: 'bo7',
                              gameTitle: 'Black Ops 7',
                            ),
                          ),
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

class _GameCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _GameCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Ink(
        height: 170,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(
              blurRadius: 18,
              spreadRadius: 0,
              offset: const Offset(0, 10),
              color: Colors.black.withOpacity(0.35),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
              ),
              const Spacer(),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 18, color: Colors.white70),
                  const SizedBox(width: 8),
                  Text(
                    'Orbit Tracker',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right, size: 28),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}