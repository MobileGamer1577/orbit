import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../storage/app_settings_store.dart';
import '../storage/collection_store.dart';
import '../theme/orbit_theme.dart';
import '../widgets/orbit_glass_card.dart';

import 'fortnite_countdown_screen.dart';
import 'fortnite_festival_hub_screen.dart';
import 'fortnite_kreativ_maps_screen.dart';
import 'fortnite_cosmetics_hub_screen.dart';
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
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: const Color(0xFF07020F),
      body: OrbitBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.arrow_back, color: Colors.white.withOpacity(0.90)),
                    ),
                    const SizedBox(width: 4),
                    const Expanded(
                      child: Text('Fortnite',
                          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900,
                              color: Colors.white, letterSpacing: -0.3)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Text(l10n.hubWhatOpen,
                      style: TextStyle(color: Colors.white.withOpacity(0.50),
                          fontWeight: FontWeight.w600, fontSize: 15)),
                ),
                const SizedBox(height: 14),

                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    children: [
                      _HubCard(icon: Icons.timer, iconColor: const Color(0xFF00D4FF),
                          title: l10n.hubCountdowns, subtitle: l10n.hubCountdownsSubtitle,
                          onTap: () => _push(context, const FortniteCountdownScreen())),
                      const SizedBox(height: 10),

                      _HubCard(icon: Icons.checklist, iconColor: const Color(0xFF9C6FFF),
                          title: l10n.hubQuests, subtitle: l10n.hubQuestsSubtitle,
                          onTap: () => _push(context, ModeSelectScreen(gameId: 'fortnite', gameTitle: l10n.hubQuests))),
                      const SizedBox(height: 10),

                      _HubCard(icon: Icons.storefront, iconColor: const Color(0xFFFFD600),
                          title: l10n.hubItemShop, subtitle: l10n.hubItemShopSubtitle,
                          onTap: () => _push(context, const FortniteShopScreen())),
                      const SizedBox(height: 10),

                      // ── Ein Button für Spind + Wishlist + Alle Cosmetics ──
                      _HubCard(
                        icon: Icons.inventory_2,
                        iconColor: const Color(0xFFFF81E0),
                        title: l10n.hubCosmetics,
                        subtitle: l10n.hubCosmeticsSubtitle,
                        onTap: () => _push(context,
                            FortniteCosmeticsHubScreen(collection: collection)),
                      ),
                      const SizedBox(height: 10),

                      _HubCard(icon: Icons.music_note, iconColor: const Color(0xFFFF6B6B),
                          title: l10n.hubFestival, subtitle: l10n.hubFestivalSubtitle,
                          onTap: () => _push(context, FortniteFestivalHubScreen(collection: collection))),
                      const SizedBox(height: 10),

                      _HubCard(icon: Icons.insights, iconColor: const Color(0xFF00E676),
                          title: l10n.hubStats, subtitle: l10n.hubStatsSubtitle,
                          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.hubStatsSoon)))),
                      const SizedBox(height: 10),

                      _HubCard(icon: Icons.palette, iconColor: const Color(0xFFFF8C00),
                          title: l10n.hubKreativMaps, subtitle: l10n.hubKreativMapsSubtitle,
                          onTap: () => _push(context, const FortniteKreativMapsScreen())),
                      const SizedBox(height: 10),

                      _HubCard(icon: Icons.public, iconColor: const Color(0xFF64FFDA),
                          title: l10n.hubServerStatus, subtitle: l10n.hubServerStatusSubtitle,
                          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.hubServerStatusSoon)))),
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
    required this.icon, required this.iconColor,
    required this.title, required this.subtitle, required this.onTap,
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
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: iconColor.withOpacity(0.30), width: 1.2),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(
                        color: Colors.white.withOpacity(0.55), fontWeight: FontWeight.w500, fontSize: 13)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.35), size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
