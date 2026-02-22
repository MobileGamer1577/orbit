import 'package:flutter/material.dart';

import '../services/in_app_update_service.dart';
import '../services/update_service.dart';
import '../storage/app_settings_store.dart';
import '../storage/collection_store.dart';
import '../storage/update_store.dart';
import '../theme/orbit_theme.dart';
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
  final _updateService = UpdateService();
  final _inAppUpdateService = InAppUpdateService();

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
      final result = await _updateService.checkForUpdate();
      if (!mounted) return;

      if (result.hasUpdate) {
        await _showUpdateDialog(
          version: result.latestVersion,
          notes: result.releaseNotes,
          url: result.downloadUrl,
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
              await _inAppUpdateService.downloadAndInstallApk(url);
            },
            child: const Text('Update installieren'),
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
        builder: (_) => const ModeSelectScreen(gameId: 'bo7', gameTitle: 'BO7'),
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
                Row(
                  children: [
                    Icon(Icons.public, color: Colors.white.withOpacity(0.92)),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Orbit',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _openSettings,
                      icon: const Icon(Icons.settings, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Wähle ein Spiel',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.65),
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 16),
                _GameCard(
                  title: 'Fortnite',
                  subtitle:
                      'Aufgaben abhaken • Season-\nCountdown • Item-Shop (bald)',
                  onTap: _openFortnite,
                ),
                const SizedBox(height: 14),
                _GameCard(
                  title: 'Call of Duty: Black Ops 7',
                  subtitle:
                      'Aufgaben (Soon) • Steam Erfolge •\nCountdowns (Soon)',
                  onTap: _openBo7,
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _checking
                            ? null
                            : () => _checkUpdates(showNoUpdateToast: true),
                        icon: Icon(
                          _checking
                              ? Icons.hourglass_top
                              : Icons.system_update_alt,
                        ),
                        label: Text(_checking ? 'Prüfe…' : 'Updates prüfen'),
                      ),
                    ),
                  ],
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
    return OrbitGlassCard(
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.65),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: Colors.white.withOpacity(0.85),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Orbit Tracker',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.chevron_right,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
