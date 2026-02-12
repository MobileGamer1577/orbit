import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';

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

  Future<void> _openDesignPicker() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(14),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.white.withOpacity(0.10)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.palette, color: Colors.white),
                        const SizedBox(width: 10),
                        Text(
                          'Dark Design',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ...OrbitDarkTheme.values.map((t) {
                      final selected = widget.settings.darkTheme == t;
                      return _OptionTile(
                        title: OrbitTheme.displayName(t),
                        selected: selected,
                        onTap: () async {
                          await widget.settings.setDarkTheme(t);
                          if (ctx.mounted) Navigator.of(ctx).pop();
                        },
                      );
                    }),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
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

  Future<void> _checkUpdates() async {
    await widget.updateStore.check();
    if (!mounted) return;

    if (widget.updateStore.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Update-Check fehlgeschlagen: ${widget.updateStore.error}'),
        ),
      );
      return;
    }

    if (widget.updateStore.updateAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update verfügbar: ${widget.updateStore.latest}')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Du bist auf dem neuesten Stand ✅')),
      );
    }
  }

  Future<void> _openGithubLatest() async {
    try {
      await widget.updateStore.openLatestReleasePage();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Konnte GitHub nicht öffnen ❌\n$e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentDesignName = OrbitTheme.displayName(widget.settings.darkTheme);

    final checking = widget.updateStore.isChecking;
    final hasCheckedOnce = widget.updateStore.current.isNotEmpty ||
        widget.updateStore.latest.isNotEmpty ||
        widget.updateStore.error != null;
    final updateAvailable = widget.updateStore.updateAvailable;

    String updateSubtitle;
    if (checking) {
      updateSubtitle = 'Suche…';
    } else if (widget.updateStore.error != null) {
      updateSubtitle = 'Fehler beim Check';
    } else if (!hasCheckedOnce) {
      updateSubtitle = 'Noch nicht geprüft';
    } else if (updateAvailable) {
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
          title: const Text('Einstellungen'),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionTitle(title: 'Allgemein'),
                const SizedBox(height: 10),

                _Tile(
                  icon: Icons.info_outline,
                  title: 'Version',
                  subtitle: _versionText,
                  trailing: const Icon(Icons.chevron_right, color: Colors.white70),
                  onTap: null,
                ),
                const SizedBox(height: 10),

                _Tile(
                  icon: Icons.palette_outlined,
                  title: 'Dark Design',
                  subtitle: currentDesignName,
                  trailing: const Icon(Icons.chevron_right, color: Colors.white70),
                  onTap: _openDesignPicker,
                ),

                const SizedBox(height: 18),
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
                      : const Icon(Icons.chevron_right, color: Colors.white70),
                  onTap: _checkUpdates,
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: checking ? null : _checkUpdates,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Check'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _openGithubLatest,
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('GitHub'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),
                const _SectionTitle(title: 'Zurücksetzen'),
                const SizedBox(height: 10),

                _Tile(
                  icon: Icons.restart_alt,
                  title: 'Fortschritt zurücksetzen',
                  subtitle: 'Checkbox-Status löschen',
                  trailing: const Icon(Icons.chevron_right, color: Colors.white70),
                  onTap: _resetTasks,
                ),
                const SizedBox(height: 10),

                _Tile(
                  icon: Icons.settings_backup_restore,
                  title: 'Einstellungen zurücksetzen',
                  subtitle: 'Design & Settings zurücksetzen',
                  trailing: const Icon(Icons.chevron_right, color: Colors.white70),
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

class _OptionTile extends StatelessWidget {
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _OptionTile({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(selected ? 0.14 : 0.07),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? Colors.white.withOpacity(0.35)
                : Colors.white.withOpacity(0.10),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            if (selected) const Icon(Icons.check_circle, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

/// =========================
/// UI Helpers
/// =========================
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context)
          .textTheme
          .titleMedium
          ?.copyWith(color: Colors.white70, fontWeight: FontWeight.w800),
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
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: Colors.white.withOpacity(0.9)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            trailing,
          ],
        ),
      ),
    );
  }
}