import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/update_service.dart';
import '../storage/app_settings_store.dart';
import '../storage/update_store.dart';
import '../theme/orbit_theme.dart';

class SettingsScreen extends StatefulWidget {
  final AppSettingsStore settings;
  final UpdateStore updateStore;

  const SettingsScreen({
    super.key,
    required this.settings,
    required this.updateStore,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _versionText = '…';
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() => _versionText = '${info.version}+${info.buildNumber}');
  }

  Future<void> _checkUpdates() async {
    if (_checking) return;
    setState(() => _checking = true);
    try {
      final result = await UpdateService.checkForUpdates();
      if (!mounted) return;
      if (result.updateAvailable) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update verfügbar: ${result.latest} 🚀')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Keine Updates gefunden ✅')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Update-Check fehlgeschlagen.')),
        );
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _openGithubLatest() async {
    final url = Uri.parse(
      'https://github.com/MobileGamer1577/orbit/releases/latest',
    );
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('GitHub konnte nicht geöffnet werden.')),
        );
      }
    }
  }

  Future<void> _resetTasks() async {
    final box = await Hive.openBox('task_state');
    await box.clear();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fortschritt zurückgesetzt ✅')),
    );
  }

  Future<void> _resetSettings() async {
    final settingsBox = await Hive.openBox('settings');
    await settingsBox.clear();
    widget.settings.reloadFromBox();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Einstellungen zurückgesetzt ✅')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String updateSubtitle;
    if (widget.updateStore.isChecking) {
      updateSubtitle = 'Wird geprüft…';
    } else if (widget.updateStore.updateAvailable) {
      updateSubtitle = 'Update verfügbar: ${widget.updateStore.latest}';
    } else {
      updateSubtitle = 'Aktuell ✅';
    }

    return OrbitBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Einstellungen',
            style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Allgemein ──────────────────────────────
                const _SectionTitle(title: 'Allgemein'),
                const SizedBox(height: 10),
                _Tile(
                  icon: Icons.info_outline,
                  iconColor: const Color(0xFF9C6FFF),
                  title: 'Version',
                  subtitle: _versionText,
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: Colors.white24,
                  ),
                  onTap: null,
                ),

                // ── Updates ────────────────────────────────
                const SizedBox(height: 22),
                const _SectionTitle(title: 'Updates'),
                const SizedBox(height: 10),
                _Tile(
                  icon: Icons.system_update_alt,
                  iconColor: const Color(0xFF00D4FF),
                  title: 'Update-Status',
                  subtitle: updateSubtitle,
                  trailing: _checking
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(
                          Icons.chevron_right,
                          color: Colors.white24,
                        ),
                  onTap: _checkUpdates,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _ActionBtn(
                        icon: Icons.refresh,
                        label: 'Check',
                        onPressed: _checking ? null : _checkUpdates,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionBtn(
                        icon: Icons.open_in_new,
                        label: 'GitHub',
                        onPressed: _openGithubLatest,
                        accent: true,
                      ),
                    ),
                  ],
                ),

                // ── Zurücksetzen ───────────────────────────
                const SizedBox(height: 22),
                const _SectionTitle(title: 'Zurücksetzen'),
                const SizedBox(height: 10),
                _Tile(
                  icon: Icons.restart_alt,
                  iconColor: const Color(0xFFFF6B6B),
                  title: 'Fortschritt zurücksetzen',
                  subtitle: 'Checkbox-Status löschen',
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: Colors.white24,
                  ),
                  onTap: _resetTasks,
                ),
                const SizedBox(height: 10),
                _Tile(
                  icon: Icons.settings_backup_restore,
                  iconColor: const Color(0xFFFFD600),
                  title: 'Einstellungen zurücksetzen',
                  subtitle: 'Settings auf Standard zurücksetzen',
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: Colors.white24,
                  ),
                  onTap: _resetSettings,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Wiederverwendbare Bausteine
// ──────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        color: Colors.white.withOpacity(0.40),
        fontWeight: FontWeight.w700,
        fontSize: 11,
        letterSpacing: 1.5,
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  const _Tile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withOpacity(0.09),
                Colors.white.withOpacity(0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.10)),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                    color: iconColor.withOpacity(0.28),
                    width: 1.1,
                  ),
                ),
                child: Icon(icon, size: 19, color: iconColor),
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
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.50),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool accent;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: accent
            ? Colors.white.withOpacity(0.08)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 13),
        side: BorderSide(
          color: Colors.white.withOpacity(accent ? 0.18 : 0.14),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      icon: Icon(icon, size: 17),
      label: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}
