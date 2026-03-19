import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
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
    final l10n  = context.l10n;
    final modes = _modesFor(gameId, l10n);

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

  List<_Mode> _modesFor(String id, AppLocalizations l10n) {
    if (id == 'fortnite') {
      return [
        _Mode(
          title: l10n.modeBRTitle,
          subtitle: l10n.modeBRSubtitle,
          assetPath: 'assets/data/fortnite_br.json',
          icon: Icons.layers,
          color: const Color(0xFF00D4FF),
        ),
        _Mode(
          title: l10n.modeReloadTitle,
          subtitle: l10n.modeReloadSubtitle,
          assetPath: 'assets/data/fortnite_reload.json',
          icon: Icons.restart_alt,
          color: const Color(0xFF00C8A0),
        ),
        _Mode(
          title: l10n.modeBallisticTitle,
          subtitle: l10n.modeBallisticSubtitle,
          assetPath: 'assets/data/fortnite_ballistic.json',
          icon: Icons.sports_martial_arts,
          color: const Color(0xFFFF6B6B),
        ),
        _Mode(
          title: l10n.modeLegoTitle,
          subtitle: l10n.modeLegoSubtitle,
          assetPath: 'assets/data/fortnite_lego.json',
          icon: Icons.extension,
          color: const Color(0xFFFFD600),
        ),
        _Mode(
          title: l10n.modeDeluluTitle,
          subtitle: l10n.modeDeluluSubtitle,
          assetPath: 'assets/data/fortnite_delulu.json',
          icon: Icons.auto_awesome,
          color: const Color(0xFFFF81E0),
        ),
        _Mode(
          title: l10n.modeBlitzTitle,
          subtitle: l10n.modeBlitzSubtitle,
          assetPath: 'assets/data/fortnite_blitz_royale.json',
          icon: Icons.flash_on,
          color: const Color(0xFFFFC107),
        ),
        _Mode(
          title: l10n.modeOGTitle,
          subtitle: l10n.modeOGSubtitle,
          assetPath: 'assets/data/fortnite_og.json',
          icon: Icons.history,
          color: const Color(0xFF9C6FFF),
        ),
        _Mode(
          title: l10n.modeKreativTitle,
          subtitle: l10n.modeKreativSubtitle,
          assetPath: 'assets/data/fortnite_kreativ.json',
          icon: Icons.palette,
          color: const Color(0xFFFF6B35),
        ),
      ];
    }

    // Black Ops 7
    return [
      _Mode(
        title: l10n.modeBo7CoopTitle,
        subtitle: l10n.modeBo7CoopSubtitle,
        assetPath: 'assets/data/bo7_koop_endspiel.json',
        icon: Icons.handshake,
        color: const Color(0xFF4CAF50),
      ),
      _Mode(
        title: l10n.modeBo7MPTitle,
        subtitle: l10n.modeBo7MPSubtitle,
        assetPath: 'assets/data/bo7_mp.json',
        icon: Icons.sports_esports,
        color: const Color(0xFFFF6B35),
      ),
      _Mode(
        title: l10n.modeBo7ZombiesTitle,
        subtitle: l10n.modeBo7ZombiesSubtitle,
        assetPath: 'assets/data/bo7_zombies.json',
        icon: Icons.bug_report,
        color: const Color(0xFF76FF03),
      ),
      _Mode(
        title: l10n.modeBo7WarzoneTitle,
        subtitle: l10n.modeBo7WarzoneSubtitle,
        assetPath: 'assets/data/bo7_warzone.json',
        icon: Icons.public,
        color: const Color(0xFF00B0FF),
      ),
    ];
  }
}

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
