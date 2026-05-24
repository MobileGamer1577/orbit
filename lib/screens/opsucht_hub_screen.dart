import 'package:flutter/material.dart';

import '../theme/orbit_theme.dart';
import '../widgets/orbit_glass_card.dart';
import '../services/opsucht_sync_service.dart';

import 'opsucht_oppass_screen.dart';
import 'opsucht_items_screen.dart';

// ══════════════════════════════════════════════════════════════
//
//  🟢 OPSUCHT HUB SCREEN
//  Datei: lib/screens/opsucht_hub_screen.dart
//
//  Hauptmenü für OpSucht.net Features:
//    • OPPASS  → Season Bilder Galerie
//    • Items   → Item Datenbank
//
// ══════════════════════════════════════════════════════════════

class OpSuchtHubScreen extends StatefulWidget {
  const OpSuchtHubScreen({super.key});

  @override
  State<OpSuchtHubScreen> createState() => _OpSuchtHubScreenState();
}

class _OpSuchtHubScreenState extends State<OpSuchtHubScreen> {
  @override
  void initState() {
    super.initState();
    // Season-Daten laden für den Header
    OpSuchtSyncService.instance.loadSeason();
    OpSuchtSyncService.instance.addListener(_onUpdate);
  }

  @override
  void dispose() {
    OpSuchtSyncService.instance.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  void _push(BuildContext context, Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    final service = OpSuchtSyncService.instance;
    final season  = service.season;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: OrbitBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ────────────────────────────────
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'OpSucht.net',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                          Text(
                            'OPPASS • Items • und mehr',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.50),
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Refresh-Button
                    IconButton(
                      onPressed: () =>
                          OpSuchtSyncService.instance.forceRefreshAll(),
                      icon: Icon(
                        Icons.refresh,
                        color: Colors.white.withOpacity(0.70),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // ── Season Banner ─────────────────────────
                if (service.seasonLoaded) _SeasonBanner(season: season),

                const SizedBox(height: 16),

                // ── Hub Karten ────────────────────────────
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    children: [
                      // OPPASS
                      _HubCard(
                        icon: Icons.photo_library_outlined,
                        iconColor: const Color(0xFF00D4FF),
                        title: 'OPPASS',
                        subtitle: 'Season Bilder & Übersicht',
                        badge: service.oppassImages.isEmpty
                            ? null
                            : '${service.oppassImages.length} Bilder',
                        onTap: () => _push(context, const OpSuchtOppassScreen()),
                      ),
                      const SizedBox(height: 12),

                      // Items
                      _HubCard(
                        icon: Icons.inventory_2_outlined,
                        iconColor: const Color(0xFF00E676),
                        title: 'Item Datenbank',
                        subtitle: 'Alle OpSucht Items durchsuchen',
                        badge: service.items.isNotEmpty
                            ? '${service.items.length} Items'
                            : null,
                        onTap: () => _push(context, const OpSuchtItemsScreen()),
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

// ──────────────────────────────────────────────────────────────
//  Season Banner
// ──────────────────────────────────────────────────────────────

class _SeasonBanner extends StatefulWidget {
  final OpSuchtSeasonData season;
  const _SeasonBanner({required this.season});

  @override
  State<_SeasonBanner> createState() => _SeasonBannerState();
}

class _SeasonBannerState extends State<_SeasonBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double>   _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    if (widget.season.isEndingVeryLoon) {
      _pulseCtrl.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  String _buildCountdownText() {
    final rem = widget.season.timeRemaining;
    if (rem.isNegative) return 'Season beendet';
    if (rem.inHours < 24) {
      return '${rem.inHours} Stunden verbleibend';
    }
    return '${rem.inDays} Tage verbleibend';
  }

  @override
  Widget build(BuildContext context) {
    final season      = widget.season;
    final isEndingSoon = season.isEndingSoon;
    final isVeryLoon   = season.isEndingVeryLoon;
    final countdownColor = isVeryLoon
        ? const Color(0xFFFF1744)
        : isEndingSoon
        ? const Color(0xFFFF8C00)
        : const Color(0xFF00D4FF);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: OrbitGlassCard(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Season Name
            Text(
              '${season.name} Season',
              style: const TextStyle(
                color:      Colors.white,
                fontSize:   18,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),

            // Countdown + "endet bald" Badge
            Row(
              children: [
                // Countdown
                ScaleTransition(
                  scale: _pulseAnim,
                  child: Text(
                    _buildCountdownText(),
                    style: TextStyle(
                      color:      countdownColor,
                      fontSize:   15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const Spacer(),

                // "Season endet bald" Badge
                if (isEndingSoon)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color:        countdownColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border:       Border.all(
                          color: countdownColor.withOpacity(0.45)),
                    ),
                    child: Text(
                      isVeryLoon ? '⚠ < 24h' : 'Season endet bald',
                      style: TextStyle(
                        color:      countdownColor,
                        fontSize:   11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 10),

            // Progress Bar (Season-Fortschritt)
            Builder(builder: (_) {
              final total   = season.seasonEnd.difference(season.seasonStart);
              final elapsed = DateTime.now().difference(season.seasonStart);
              final progress = (elapsed.inMilliseconds /
                      total.inMilliseconds.toDouble())
                  .clamp(0.0, 1.0);
              return ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value:           progress,
                  minHeight:       5,
                  backgroundColor: Colors.white.withOpacity(0.10),
                  valueColor: AlwaysStoppedAnimation(countdownColor),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  Hub-Karte
// ──────────────────────────────────────────────────────────────

class _HubCard extends StatelessWidget {
  final IconData  icon;
  final Color     iconColor;
  final String    title;
  final String    subtitle;
  final String?   badge;
  final VoidCallback onTap;

  const _HubCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
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
                  color:        iconColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(15),
                  border:       Border.all(
                      color: iconColor.withOpacity(0.35), width: 1.2),
                ),
                child: Icon(icon, color: iconColor, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            color:      Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize:   18)),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: TextStyle(
                            color:      Colors.white.withOpacity(0.55),
                            fontWeight: FontWeight.w500,
                            fontSize:   13,
                            height:     1.3)),
                  ],
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color:        iconColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border:       Border.all(
                        color: iconColor.withOpacity(0.30)),
                  ),
                  child: Text(badge!,
                      style: TextStyle(
                          color:      iconColor,
                          fontSize:   11,
                          fontWeight: FontWeight.w700)),
                ),
              ],
              const SizedBox(width: 8),
              Icon(Icons.chevron_right,
                  color: Colors.white.withOpacity(0.40)),
            ],
          ),
        ),
      ),
    );
  }
}
