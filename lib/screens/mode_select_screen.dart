import 'package:flutter/material.dart';

import '../theme/orbit_theme.dart';
import '../widgets/orbit_glass_card.dart';
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
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
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
                    'Wähle einen Modus',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.50),
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Modus-Liste
                Expanded(
                  child: ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: modes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final m = modes[i];
                      return _ModeCard(
                        icon: m.icon,
                        iconColor: m.color,
                        title: m.title,
                        subtitle: m.subtitle,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TaskListScreen(
                              title: '$gameTitle – ${m.title}',
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

  List<_Mode> _modesFor(String id) {
    if (id == 'fortnite') {
      return const [
        _Mode(
          title: 'Battle Royale',
          subtitle: 'Aufträge für Battle Royale',
          assetPath: 'assets/data/fortnite_br.json',
          icon: Icons.layers,
          color: Color(0xFF00D4FF),
        ),
        _Mode(
          title: 'Fortnite Reload',
          subtitle: 'Aufträge für Reload',
          assetPath: 'assets/data/fortnite_reload.json',
          icon: Icons.restart_alt,
          color: Color(0xFF00C8A0),
        ),
        _Mode(
          title: 'Ballistic',
          subtitle: 'Aufträge für Ballistic',
          assetPath: 'assets/data/fortnite_ballistic.json',
          icon: Icons.sports_martial_arts,
          color: Color(0xFFFF6B6B),
        ),
        _Mode(
          title: 'LEGO Fortnite',
          subtitle: 'Aufträge für LEGO Fortnite',
          assetPath: 'assets/data/fortnite_lego.json',
          icon: Icons.extension,
          color: Color(0xFFFFD600),
        ),
        _Mode(
          title: 'Delulu',
          subtitle: 'Aufträge für Delulu',
          assetPath: 'assets/data/fortnite_delulu.json',
          icon: Icons.auto_awesome,
          color: Color(0xFFFF81E0),
        ),
        _Mode(
          title: 'Blitz Royale',
          subtitle: 'Aufträge für Blitz Royale',
          assetPath: 'assets/data/fortnite_blitz_royale.json',
          icon: Icons.flash_on,
          color: Color(0xFFFFC107),
        ),
        _Mode(
          title: 'OG',
          subtitle: 'Aufträge für OG Fortnite',
          assetPath: 'assets/data/fortnite_og.json',
          icon: Icons.history,
          color: Color(0xFF9C6FFF),
        ),
      ];
    }

    // Black Ops 7
    return const [
      _Mode(
        title: 'Koop & Endspiel',
        subtitle: 'Weekly-Aufgaben (Soon) • Visitenkarten (Soon)',
        assetPath: 'assets/data/bo7_koop_endspiel.json',
        icon: Icons.handshake,
        color: Color(0xFF4CAF50),
      ),
      _Mode(
        title: 'Mehrspieler',
        subtitle: 'Erfolge • Weekly-Aufgaben (Soon) • Tarnungen (Soon)',
        assetPath: 'assets/data/bo7_mp.json',
        icon: Icons.sports_esports,
        color: Color(0xFFFF6B35),
      ),
      _Mode(
        title: 'Zombies',
        subtitle: 'Erfolge • Weekly-Aufgaben (Soon) • Tarnungen (Soon)',
        assetPath: 'assets/data/bo7_zombies.json',
        icon: Icons.bug_report,
        color: Color(0xFF76FF03),
      ),
      _Mode(
        title: 'Warzone',
        subtitle: 'Weekly-Aufgaben (Soon) • Visitenkarten (Soon)',
        assetPath: 'assets/data/bo7_warzone.json',
        icon: Icons.public,
        color: Color(0xFF00B0FF),
      ),
    ];
  }
}

// ──────────────────────────────────────────────
// Daten-Klasse
// ──────────────────────────────────────────────
class _Mode {
  final String title;
  final String subtitle;
  final String assetPath;
  final IconData icon;
  final Color color;

  const _Mode({
    required this.title,
    required this.subtitle,
    required this.assetPath,
    required this.icon,
    required this.color,
  });
}

// ──────────────────────────────────────────────
// Modus-Karte
// ──────────────────────────────────────────────
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
              // Farbiges Icon-Badge
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

              // Texte
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
