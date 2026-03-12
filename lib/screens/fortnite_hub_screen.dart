import 'package:flutter/material.dart';

import '../storage/app_settings_store.dart';
import '../storage/collection_store.dart';
import '../theme/orbit_theme.dart';
import '../widgets/orbit_glass_card.dart';

import 'fortnite_countdown_screen.dart';
import 'fortnite_festival_hub_screen.dart';
import 'fortnite_locker_screen.dart';
import 'fortnite_shop_screen.dart';
import 'mode_select_screen.dart';

class FortniteHubScreen extends StatelessWidget {
  final AppSettingsStore settings;
  final CollectionStore collection;

  const FortniteHubScreen({
    super.key,
    required this.settings,
    required this.collection,
  });

  void _push(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07020F),
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
                    const Expanded(
                      child: Text(
                        'Fortnite',
                        style: TextStyle(
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
                    'Was willst du öffnen?',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.50),
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    children: [
                      _HubCard(
                        icon: Icons.timer,
                        iconColor: const Color(0xFF00D4FF),
                        title: 'Countdowns',
                        subtitle: 'Season Pässe & Ablaufdaten',
                        onTap: () =>
                            _push(context, const FortniteCountdownScreen()),
                      ),
                      const SizedBox(height: 10),
                      _HubCard(
                        icon: Icons.checklist,
                        iconColor: const Color(0xFF9C6FFF),
                        title: 'Aufträge',
                        subtitle: 'BR, Reload, Ballistic, LEGO, OG…',
                        onTap: () => _push(
                          context,
                          const ModeSelectScreen(
                            gameId: 'fortnite',
                            gameTitle: 'Aufträge',
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // ── Item Shop ── jetzt aktiv!
                      _HubCard(
                        icon: Icons.storefront,
                        iconColor: const Color(0xFFFFD600),
                        title: 'Item-Shop',
                        subtitle: 'Täglicher Shop • stündlich aktualisiert',
                        onTap: () =>
                            _push(context, const FortniteShopScreen()),
                      ),

                      const SizedBox(height: 10),
                      _HubCard(
                        icon: Icons.insights,
                        iconColor: const Color(0xFF00E676),
                        title: 'Stats',
                        subtitle: 'Kommt bald',
                        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Stats kommen bald ✅'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _HubCard(
                        icon: Icons.inventory_2,
                        iconColor: const Color(0xFFFF81E0),
                        title: 'Spind',
                        subtitle: 'Alle Cosmetics (aktuell: Songs)',
                        onTap: () => _push(
                          context,
                          FortniteLockerScreen(collection: collection),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _HubCard(
                        icon: Icons.music_note,
                        iconColor: const Color(0xFFFF6B6B),
                        title: 'Festival',
                        subtitle: 'Songs suchen & Playlist bauen',
                        onTap: () => _push(
                          context,
                          FortniteFestivalHubScreen(collection: collection),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _HubCard(
                        icon: Icons.public,
                        iconColor: const Color(0xFF64FFDA),
                        title: 'Status',
                        subtitle: 'Kommt bald (Server/Services)',
                        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Status kommt bald ✅'),
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

class _HubCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _HubCard({
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
