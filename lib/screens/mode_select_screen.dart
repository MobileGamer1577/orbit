import 'package:flutter/material.dart';

import '../theme/orbit_theme.dart';
import 'task_list_screen.dart';

class ModeSelectScreen extends StatelessWidget {
  final String gameId;
  final String gameTitle;

  const ModeSelectScreen({
    super.key,
    required this.gameId,
    required this.gameTitle,
  });

  @override
  Widget build(BuildContext context) {
    final modes = _modesFor(gameId);

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
                      gameTitle,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Subtitle
                Text(
                  'Wähle einen Modus',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 14),

                Expanded(
                  child: ListView.separated(
                    itemCount: modes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final m = modes[i];
                      return _ModeCard(
                        icon: m.icon,
                        title: m.title,
                        subtitle: m.subtitle,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TaskListScreen(
                              title: '${gameTitle} – ${m.title}',
                              jsonAssetPath: m.assetPath,
                            ),
                          ),
                        ),
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

  List<_Mode> _modesFor(String gameId) {
    if (gameId == 'fortnite') {
      // Fortnite: Aufträge/ToDos (kein Zero Build extra – BR ist "Standard")
      return const [
        _Mode(
          title: 'Battle Royale',
          subtitle: 'Quests/ToDos für BR',
          assetPath: 'assets/data/fortnite_br.json',
          icon: Icons.layers,
        ),
        _Mode(
          title: 'Reload',
          subtitle: 'Reload Quests/ToDos',
          assetPath: 'assets/data/fortnite_reload.json',
          icon: Icons.refresh,
        ),
        _Mode(
          title: 'Ballistic',
          subtitle: 'Ballistic Quests/ToDos',
          assetPath: 'assets/data/fortnite_ballistic.json',
          icon: Icons.shield_outlined,
        ),
        _Mode(
          title: 'LEGO Fortnite',
          subtitle: 'LEGO Pass / Ninjago / Aufgaben',
          assetPath: 'assets/data/fortnite_lego.json',
          icon: Icons.directions_car_filled_outlined,
        ),
        _Mode(
          title: 'Delulu',
          subtitle: 'Delulu Aufgaben/ToDos',
          assetPath: 'assets/data/fortnite_delulu.json',
          icon: Icons.emoji_emotions_outlined,
        ),
        _Mode(
          title: 'Blitz Royale',
          subtitle: 'Blitz Royale Aufgaben/ToDos',
          assetPath: 'assets/data/fortnite_blitz_royale.json',
          icon: Icons.flash_on,
        ),
        _Mode(
          title: 'OG',
          subtitle: 'OG / Classic Aufgaben/ToDos',
          assetPath: 'assets/data/fortnite_og.json',
          icon: Icons.history_toggle_off,
        ),
        _Mode(
          title: 'Rocket Racing',
          subtitle: 'Races / Quests / Pass',
          assetPath: 'assets/data/fortnite_rocket_racing.json',
          icon: Icons.rocket_launch_outlined,
        ),
        _Mode(
          title: 'Festival',
          subtitle: 'Musik Pass / Quests',
          assetPath: 'assets/data/fortnite_festival.json',
          icon: Icons.music_note,
        ),
      ];
    }

    // ===== Black Ops 7: genau deine Liste =====
    return const [
      _Mode(
        title: 'Koop & Endspiel',
        subtitle: 'Weekly-Aufgaben (Soon) • Visitenkarten (Soon)',
        assetPath: 'assets/data/bo7_koop_endspiel.json',
        icon: Icons.handshake,
      ),
      _Mode(
        title: 'Mehrspieler',
        subtitle: 'Erfolge • Weekly-Aufgaben (Soon) • Tarnungen (Soon)',
        assetPath: 'assets/data/bo7_mp.json',
        icon: Icons.sports_esports,
      ),
      _Mode(
        title: 'Zombies',
        subtitle: 'Erfolge • Weekly-Aufgaben (Soon) • Tarnungen (Soon)',
        assetPath: 'assets/data/bo7_zombies.json',
        icon: Icons.bug_report,
      ),
      _Mode(
        title: 'Warzone',
        subtitle: 'Weekly-Aufgaben (Soon) • Visitenkarten (Soon)',
        assetPath: 'assets/data/bo7_warzone.json',
        icon: Icons.public,
      ),
    ];
  }
}

class _Mode {
  final String title;
  final String subtitle;
  final String assetPath;
  final IconData icon;

  const _Mode({
    required this.title,
    required this.subtitle,
    required this.assetPath,
    required this.icon,
  });
}

class _ModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ModeCard({
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
