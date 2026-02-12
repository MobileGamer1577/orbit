import 'package:flutter/material.dart';

import '../storage/app_settings_store.dart';
import '../storage/update_store.dart';
import 'mode_select_screen.dart';
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

    // Popup nur einmal pro App-Start (wenn Update verfügbar)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (widget.updateStore.shouldShowPopup) {
        widget.updateStore.markPopupShown();

        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Update verfügbar 🎉'),
            content: Text(
              'Aktuell: ${widget.updateStore.current}\n'
              'Neu: ${widget.updateStore.latest}\n\n'
              '${widget.updateStore.notes ?? ''}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Später'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  try {
                    await widget.updateStore.downloadAndInstall();
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Update fehlgeschlagen: $e')),
                    );
                  }
                },
                child: const Text('Installieren'),
              ),
            ],
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasUpdate = widget.updateStore.updateAvailable;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Orbit',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Stack(
                    children: [
                      IconButton(
                        tooltip: 'Einstellungen',
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SettingsScreen(
                              settings: widget.settings,
                              updateStore: widget.updateStore, // ✅ FIX
                            ),
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
                            decoration: const BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  children: [
                    _GameCard(
                      title: 'Fortnite',
                      subtitle: 'Quests / Fortschritt',
                      icon: Icons.videogame_asset,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ModeSelectScreen(
                            title: 'Fortnite',
                            modes: const ['Battle Royale'],
                            jsonFiles: const ['assets/data/fortnite_br.json'],
                            settings: widget.settings,
                          ),
                        ),
                      ),
                    ),
                    _GameCard(
                      title: 'BO7',
                      subtitle: 'Erfolge / Checklisten',
                      icon: Icons.sports_esports,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ModeSelectScreen(
                            title: 'BO7',
                            modes: const ['MP', 'Zombies', 'Warzone', 'Koop Endspiel'],
                            jsonFiles: const [
                              'assets/data/bo7_mp.json',
                              'assets/data/bo7_zombies.json',
                              'assets/data/bo7_warzone.json',
                              'assets/data/bo7_koop_endspiel.json',
                            ],
                            settings: widget.settings,
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
    );
  }
}

class _GameCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _GameCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white.withOpacity(0.06),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 34),
            const Spacer(),
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}