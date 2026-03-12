import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

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
  bool checking = false;

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
    // Implementierung kommt vom UpdateService – hier nur State
    setState(() => checking = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => checking = false);
  }

  Future<void> _openGithubLatest() async {
    final url = Uri.parse('https://github.com/MobileGamer1577/orbit/releases/latest');
    if (await canLaunchUrl(url)) launchUrl(url, mode: LaunchMode.externalApplication);
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
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Allgemein ──────────────────────────────
                const _SectionTitle(title: 'Allgemein'),
                const SizedBox(height: 10),

                _Tile(
                  icon: Icons.info_outline,
                  title: 'Version',
                  subtitle: _versionText,
                  trailing: const Icon(Icons.chevron_right, color: Colors.white38),
                  onTap: null,
                ),

                // ── Updates ────────────────────────────────
                const SizedBox(height: 22),
                const _SectionTitle(title: 'Updates'),
                const SizedBox(height: 10),

                _Tile(
                  icon: Icons.system_update_alt,
                  title: 'Update-Status',
                  subtitle: updateSubtitle,
                  trailing: checking
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.chevron_right, color: Colors.white38),
                  onTap: _checkUpdates,
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: _OutlineBtn(
                        icon: Icons.refresh,
                        label: 'Check',
                        onPressed: checking ? null : _checkUpdates,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _OutlineBtn(
                        icon: Icons.open_in_new,
                        label: 'GitHub',
                        onPressed: _openGithubLatest,
                        filled: true,
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
                  title: 'Fortschritt zurücksetzen',
                  subtitle: 'Checkbox-Status löschen',
                  trailing: const Icon(Icons.chevron_right, color: Colors.white38),
                  onTap: _resetTasks,
                ),
                const SizedBox(height: 10),

                _Tile(
                  icon: Icons.settings_backup_restore,
                  title: 'Einstellungen zurücksetzen',
                  subtitle: 'Settings auf Standard zurücksetzen',
                  trailing: const Icon(Icons.chevron_right, color: Colors.white38),
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

// ─────────────────────────────────────────────────────────
// Wiederverwendbare UI-Bausteine
// ─────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        color: Colors.white.withOpacity(0.45),
        fontWeight: FontWeight.w700,
        fontSize: 11,
        letterSpacing: 1.4,
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  const _Tile({
    required this.icon,
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
          padding: const EdgeInsets.all(16),
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
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: Colors.white.withOpacity(0.85)),
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
                        color: Colors.white.withOpacity(0.55),
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

class _OutlineBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool filled;

  const _OutlineBtn({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    if (filled) {
      return FilledButton.icon(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(0.12),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: Colors.white.withOpacity(0.15)),
          ),
        ),
        icon: Icon(icon, size: 17),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      );
    }
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 13),
        side: BorderSide(color: Colors.white.withOpacity(0.18)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      icon: Icon(icon, size: 17),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}
