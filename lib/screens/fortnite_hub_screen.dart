import 'package:flutter/material.dart';

import '../storage/app_settings_store.dart';
import '../storage/update_store.dart';
import '../theme/orbit_theme.dart';
import 'fortnite_countdown_screen.dart';
import 'fortnite_festival_hub_screen.dart';
import 'mode_select_screen.dart';

class FortniteHubScreen extends StatelessWidget {
  final AppSettingsStore settings;
  final UpdateStore updateStore;

  const FortniteHubScreen({
    super.key,
    required this.settings,
    required this.updateStore,
  });

  void _push(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
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
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Fortnite',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Was willst du öffnen?',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 14),

                Expanded(
                  child: ListView(
                    children: [
                      _HubCard(
                        icon: Icons.timer,
                        title: 'Countdowns',
                        subtitle:
                            'Season-Ende, Festival-Season, Events (bald mehr)',
                        onTap: () => _push(
                          context,
                          FortniteCountdownScreen(settings: settings),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _HubCard(
                        icon: Icons.checklist,
                        title: 'Aufträge',
                        subtitle: 'BR, Reload, Ballistic, LEGO, OG…',
                        onTap: () => _push(
                          context,
                          const ModeSelectScreen(
                            gameId: 'fortnite',
                            gameTitle: 'Fortnite',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _HubCard(
                        icon: Icons.storefront,
                        title: 'Item-Shop',
                        subtitle: 'Kommt bald (API / später)',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Item-Shop kommt bald ✅'),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _HubCard(
                        icon: Icons.insights,
                        title: 'Stats',
                        subtitle: 'Kommt bald (API später)',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Stats kommen bald ✅'),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _HubCard(
                        icon: Icons.music_note,
                        title: 'Festival',
                        subtitle: 'Songs suchen & Playlist bauen',
                        onTap: () =>
                            _push(context, const FortniteFestivalHubScreen()),
                      ),
                      const SizedBox(height: 12),
                      _HubCard(
                        icon: Icons.public,
                        title: 'Status',
                        subtitle: 'Kommt bald (Server/Services)',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Status kommt bald ✅'),
                            ),
                          );
                        },
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

class _HubCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _HubCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 26),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 28),
          ],
        ),
      ),
    );
  }
}
