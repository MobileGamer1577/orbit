import 'package:flutter/material.dart';

import '../theme/orbit_theme.dart';
import '../storage/app_settings_store.dart';
import 'mode_select_screen.dart';
import 'fortnite_hub_screen.dart';
import 'settings_screen.dart';

class GameSelectScreen extends StatelessWidget {
  final AppSettingsStore settings;

  const GameSelectScreen({super.key, required this.settings});

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
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.public, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      'Orbit',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const Spacer(),

                    // ✅ Settings Button
                    IconButton(
                      tooltip: 'Einstellungen',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SettingsScreen(settings: settings),
                          ),
                        );
                      },
                      icon: const Icon(Icons.settings),
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
                        subtitle:
                            'Aufgaben abhaken • Season-Countdown • Item-Shop (bald)',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const FortniteHubScreen(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _GameCard(
                        title: 'Call of Duty: Black Ops 7',
                        subtitle:
                            'Aufgaben (Soon) • Steam Erfolge • Countdowns (Soon)',
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
                  const Icon(Icons.calendar_today,
                      size: 18, color: Colors.white70),
                  const SizedBox(width: 8),
                  Text(
                    'Orbit Tracker',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.white70),
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