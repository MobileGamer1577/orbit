import 'package:flutter/material.dart';

import '../storage/app_settings_store.dart';
import '../storage/update_store.dart';
import '../theme/orbit_theme.dart';

import 'fortnite_hub_screen.dart';
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybeShowUpdatePopup();
  }

  void _maybeShowUpdatePopup() {
    if (!widget.updateStore.shouldShowPopup) return;

    widget.updateStore.markPopupShown();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final latest = widget.updateStore.latest;
      final notes = widget.updateStore.notes;
      final url = widget.updateStore.url;

      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Update verfügbar'),
          content: Text(
            'Neue Version: $latest\n\n'
            '${(notes ?? '').trim().isEmpty ? '' : 'Infos:\n$notes\n\n'}'
            'Jetzt installieren?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Später'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                if (url == null || url.trim().isEmpty) return;

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
    });
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SettingsScreen(
          settings: widget.settings,
          updateStore: widget.updateStore,
        ),
      ),
    );
  }

  void _openFortnite() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FortniteHubScreen(settings: widget.settings),
      ),
    );
  }

  void _openBo7() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ModeSelectScreen(gameId: 'bo7', gameTitle: 'BO7'),
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
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Bar
                Row(
                  children: [
                    const Icon(Icons.public, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      'Orbit',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: _openSettings,
                      icon: const Icon(Icons.settings),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Wähle ein Spiel',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 22),

                // Fortnite Block
                _GameBlock(
                  title: 'Fortnite',
                  subtitle:
                      'Aufträge abhaken • Season-Countdown • Item-Shop (bald)',
                  onTap: _openFortnite,
                ),

                const SizedBox(height: 20),

                // BO7 Block
                _GameBlock(
                  title: 'Call of Duty: Black Ops 7',
                  subtitle:
                      'Aufgaben (Soon) • Steam Erfolge • Countdowns (Soon)',
                  onTap: _openBo7,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GameBlock extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _GameBlock({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 14),
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Ink(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_month_outlined,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Orbit Tracker',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right, size: 26),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
