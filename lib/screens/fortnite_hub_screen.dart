import 'package:flutter/material.dart';

import '../storage/app_settings_store.dart';
import '../theme/orbit_theme.dart';
import 'fortnite_countdown_screen.dart';
import 'mode_select_screen.dart';

class FortniteHubScreen extends StatelessWidget {
  final AppSettingsStore settings;

  const FortniteHubScreen({super.key, required this.settings});

  void _comingSoon(BuildContext context, String featureName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$featureName kommt bald ✅'),
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
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Bar
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
                    ),
                    Text(
                      'Fortnite',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                Text(
                  'Was willst du machen?',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 14),

                Expanded(
                  child: ListView(
                    children: [
                      _OrbitNavCard(
                        icon: Icons.timer_outlined,
                        title: 'Countdown',
                        subtitle: 'Season-Ende (bald)',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const FortniteCountdownScreen(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _OrbitNavCard(
                        icon: Icons.checklist_outlined,
                        title: 'Aufträge',
                        subtitle:
                            'Battle Royale • Reload • Ballistic • LEGO • OG • …',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ModeSelectScreen(
                              gameId: 'fortnite',
                              gameTitle: 'Aufträge',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _OrbitNavCard(
                        icon: Icons.storefront_outlined,
                        title: 'Shop',
                        subtitle:
                            'Item-Shop & Bundles (bald – mit Favoriten/Notifs)',
                        onTap: () => _comingSoon(context, 'Shop'),
                      ),
                      const SizedBox(height: 12),
                      _OrbitNavCard(
                        icon: Icons.bar_chart_rounded,
                        title: 'Stats',
                        subtitle:
                            'Deine Stats/Übersichten (bald – mit Account-Verknüpfung)',
                        onTap: () => _comingSoon(context, 'Stats'),
                      ),
                      const SizedBox(height: 12),
                      _OrbitNavCard(
                        icon: Icons.music_note_outlined,
                        title: 'Festival',
                        subtitle:
                            'Songs suchen • Schwierigkeiten • Playlist-Builder (bald)',
                        onTap: () => _comingSoon(context, 'Festival'),
                      ),
                      const SizedBox(height: 12),
                      _OrbitNavCard(
                        icon: Icons.info_outline,
                        title: 'Status',
                        subtitle: 'Serverstatus / Downtime / Hotfixes (bald)',
                        onTap: () => _comingSoon(context, 'Status'),
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

class _OrbitNavCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _OrbitNavCard({
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
                      fontWeight: FontWeight.w800,
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
