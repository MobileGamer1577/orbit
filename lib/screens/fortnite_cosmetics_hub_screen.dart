import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../storage/collection_store.dart';
import '../theme/orbit_theme.dart';
import '../widgets/orbit_glass_card.dart';

import 'fortnite_cosmetics_locker_screen.dart';
import 'fortnite_all_cosmetics_screen.dart';

class FortniteCosmeticsHubScreen extends StatelessWidget {
  final CollectionStore collection;

  const FortniteCosmeticsHubScreen({super.key, required this.collection});

  void _push(BuildContext context, Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: OrbitBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ─────────────────────────────────
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.arrow_back, color: Colors.white.withOpacity(0.90)),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(l10n.hubCosmetics,
                          style: const TextStyle(
                            fontSize: 26, fontWeight: FontWeight.w900,
                            color: Colors.white, letterSpacing: -0.3)),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 16),
                  child: Text(l10n.cosmeticsWhatOpen,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.50),
                          fontWeight: FontWeight.w600, fontSize: 15)),
                ),

                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    children: [
                      // ── Mein Spind ──────────────────────
                      _HubCard(
                        icon: Icons.inventory_2_outlined,
                        iconColor: const Color(0xFFFF81E0),
                        title: l10n.cosmeticsMyLocker,
                        subtitle: l10n.cosmeticsSubtitleOwned,
                        onTap: () => _push(context,
                            FortniteCosmeticsLockerScreen(collection: collection, wishlistMode: false)),
                      ),
                      const SizedBox(height: 12),

                      // ── Wunschliste ─────────────────────
                      _HubCard(
                        icon: Icons.favorite_border,
                        iconColor: const Color(0xFFFF4081),
                        title: l10n.filterWishlist,
                        subtitle: l10n.cosmeticsSubtitleWishlist,
                        onTap: () => _push(context,
                            FortniteCosmeticsLockerScreen(collection: collection, wishlistMode: true)),
                      ),
                      const SizedBox(height: 12),

                      // ── Alle Cosmetics ──────────────────
                      _HubCard(
                        icon: Icons.grid_view_rounded,
                        iconColor: const Color(0xFF00D4FF),
                        title: l10n.cosmeticsAll,
                        subtitle: l10n.cosmeticsAllSubtitle,
                        onTap: () => _push(context,
                            FortniteAllCosmeticsScreen(collection: collection)),
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
          padding: const EdgeInsets.fromLTRB(14, 18, 12, 18),
          child: Row(
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: iconColor.withOpacity(0.35), width: 1.2),
                ),
                child: Icon(icon, color: iconColor, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
                    const SizedBox(height: 5),
                    Text(subtitle, style: TextStyle(
                        color: Colors.white.withOpacity(0.55),
                        fontWeight: FontWeight.w500, fontSize: 13, height: 1.35)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.40)),
            ],
          ),
        ),
      ),
    );
  }
}
