import 'package:flutter/material.dart';

import '../services/in_app_update_service.dart';
import '../services/update_service.dart';
import '../storage/app_settings_store.dart';
import '../storage/collection_store.dart';
import '../storage/update_store.dart';
import '../theme/orbit_theme.dart';
import '../widgets/orbit_glass_card.dart';

import 'fortnite_hub_screen.dart';
import 'mode_select_screen.dart';
import 'settings_screen.dart';

class GameSelectScreen extends StatefulWidget {
  final AppSettingsStore settings;
  final UpdateStore updateStore;
  final CollectionStore collection;

  const GameSelectScreen({
    super.key,
    required this.settings,
    required this.updateStore,
    required this.collection,
  });

  @override
  State<GameSelectScreen> createState() => _GameSelectScreenState();
}

class _GameSelectScreenState extends State<GameSelectScreen> {
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _checkUpdates(showNoUpdateToast: false),
    );
  }

  Future<void> _checkUpdates({required bool showNoUpdateToast}) async {
    if (_checking) return;
    setState(() => _checking = true);

    try {
      final result = await UpdateService.checkForUpdates();

      if (!mounted) return;

      if (result.updateAvailable) {
        await _showUpdateDialog(
          version: result.latest,
          notes: result.notes ?? '',
          url: result.releaseUrl,
        );
      } else {
        if (showNoUpdateToast) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Keine Updates gefunden ✅')),
          );
        }
      }
    } catch (_) {
      if (showNoUpdateToast && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Update-Check fehlgeschlagen.')),
        );
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _showUpdateDialog({
    required String version,
    required String notes,
    required String url,
  }) async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Update verfügbar: $version'),
        content: SingleChildScrollView(
          child: Text(notes.isEmpty ? 'Release Notes fehlen.' : notes),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Später'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await InAppUpdateService.downloadAndInstallApk(apkUrl: url);
            },
            child: const Text('Release öffnen'),
          ),
        ],
      ),
    );
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SettingsScreen(
          settings: widget.settings,
          updateStore: widget.updateStore,
        ),
      ),
    );
  }

  void _openFortnite() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FortniteHubScreen(
          settings: widget.settings,
          collection: widget.collection,
        ),
      ),
    );
  }

  void _openBo7() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const ModeSelectScreen(gameId: 'bo7', gameTitle: 'BO7'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: OrbitBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF9C6FFF).withOpacity(0.35),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Icon(
                        Icons.public,
                        color: Colors.white.withOpacity(0.95),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Orbit',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _openSettings,
                      icon: Icon(
                        Icons.settings_outlined,
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),
                Text(
                  'Wähle ein Spiel',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.55),
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 20),

                // Fortnite Card
                _GameCard(
                  title: 'Fortnite',
                  subtitle: 'Aufgaben • Season-Countdown • Item-Shop (bald)',
                  accentColor: const Color(0xFF00D4FF),
                  secondaryColor: const Color(0xFF0070FF),
                  icon: Icons.bolt,
                  onTap: _openFortnite,
                ),
                const SizedBox(height: 14),

                // BO7 Card
                _GameCard(
                  title: 'Call of Duty: BO7',
                  subtitle: 'Steam Erfolge • PlayStation Trophäen • Modi',
                  accentColor: const Color(0xFFFF6B35),
                  secondaryColor: const Color(0xFFCC2200),
                  icon: Icons.military_tech,
                  onTap: _openBo7,
                ),

                const Spacer(),

                // Update Button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _checking
                        ? null
                        : () => _checkUpdates(showNoUpdateToast: true),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.10),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: Colors.white.withOpacity(0.12),
                        ),
                      ),
                    ),
                    icon: Icon(
                      _checking ? Icons.hourglass_top : Icons.system_update_alt,
                      size: 18,
                    ),
                    label: Text(
                      _checking ? 'Prüfe…' : 'Updates prüfen',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
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

// ─────────────────────────────────────────────────────────
// Game Card mit Akzentfarbe pro Spiel
// ─────────────────────────────────────────────────────────
class _GameCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color accentColor;
  final Color secondaryColor;
  final IconData icon;
  final VoidCallback onTap;

  const _GameCard({
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.secondaryColor,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OrbitGlassCard(
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          child: Row(
            children: [
              // Farbiges Icon-Badge
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accentColor.withOpacity(0.28),
                      secondaryColor.withOpacity(0.18),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: accentColor.withOpacity(0.35),
                    width: 1.2,
                  ),
                ),
                child: Icon(icon, color: accentColor, size: 26),
              ),
              const SizedBox(width: 16),

              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.60),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: Colors.white.withOpacity(0.45),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
