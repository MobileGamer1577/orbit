import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../storage/app_settings_store.dart';
import '../storage/update_store.dart';
import '../services/in_app_update_service.dart';
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

  // Download UI
  bool _downloading = false;
  int _recv = 0;
  int _total = -1;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() => _versionText = '${info.version}+${info.buildNumber}');
  }

  Future<void> _openDesignPicker() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.45),
      isScrollControlled: true,
      builder: (_) => _DesignPickerSheet(settings: widget.settings),
    );

    if (mounted) setState(() {});
  }

  Future<void> _resetAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Alles zurücksetzen?'),
        content: const Text(
          'Das setzt alles zurück (z.B. Abgeschlossene Aufgaben & alle Einstellungen)',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Zurücksetzen'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final taskBox = await Hive.openBox('task_state');
    await taskBox.clear();

    final settingsBox = await Hive.openBox('settings');
    await settingsBox.clear();

    widget.settings.reloadFromBox();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Alles zurückgesetzt ✅')),
    );
  }

  Future<void> _checkUpdates() async {
    try {
      await widget.updateStore.check();
      if (!mounted) return;

      if (widget.updateStore.updateAvailable) {
        final latest = widget.updateStore.latest ?? 'unbekannt';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update verfügbar: $latest')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Du bist auf dem neuesten Stand ✅')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update-Check fehlgeschlagen: $e')),
      );
    }
  }

  String _progressText() {
    if (_total <= 0) return 'Lade herunter…';
    final p = (_recv / _total * 100).clamp(0, 100).toStringAsFixed(0);
    return 'Lade herunter… $p%';
    }

  Future<void> _installUpdate() async {
    final r = widget.updateStore.result;
    final url = r?.url;

    if (r == null || url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kein Update-Link gefunden ❌')),
      );
      return;
    }

    setState(() {
      _downloading = true;
      _recv = 0;
      _total = -1;
    });

    try {
      await InAppUpdateService.downloadAndInstallApk(
        apkUrl: url,
        onProgress: (recv, total) {
          if (!mounted) return;
          setState(() {
            _recv = recv;
            _total = total;
          });
        },
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Installer geöffnet ✅')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Update Download/Installation fehlgeschlagen ❌\n'
            'Tipp: Erlaube „Unbekannte Apps installieren“ für Orbit.\n$e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _downloading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentDesignName = OrbitTheme.displayName(widget.settings.darkTheme);

    final checking = widget.updateStore.checking;

    final hasResult = widget.updateStore.result != null;
    final updateAvailable = widget.updateStore.updateAvailable;
    final result = widget.updateStore.result;

    String updateSubtitle;
    if (_downloading) {
      updateSubtitle = _progressText();
    } else if (checking) {
      updateSubtitle = 'Suche…';
    } else if (hasResult) {
      if (updateAvailable) {
        updateSubtitle = 'Update verfügbar: ${result!.latest}';
      } else {
        updateSubtitle = 'App ist aktuell ✅';
      }
    } else {
      updateSubtitle = 'Tippe zum Prüfen';
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: OrbitBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Einstellungen',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              _SectionTitle(title: 'Allgemein'),
              const SizedBox(height: 10),

              _Tile(
                icon: Icons.info_outline,
                title: 'App-Version',
                subtitle: _versionText,
                trailing: const SizedBox.shrink(),
                onTap: null,
              ),

              const SizedBox(height: 10),

              _Tile(
                icon: Icons.system_update_alt,
                title: 'Nach Updates suchen',
                subtitle: updateSubtitle,
                trailing: (_downloading || checking)
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh, size: 22),
                onTap: (_downloading || checking) ? null : _checkUpdates,
              ),

              if (!_downloading && !checking && updateAvailable && result != null)
                ...[
                  const SizedBox(height: 10),
                  _Tile(
                    icon: Icons.download,
                    title: 'Update installieren',
                    subtitle: 'APK herunterladen & installieren',
                    trailing: const Icon(Icons.chevron_right, size: 24),
                    onTap: _installUpdate,
                  ),
                ],

              const SizedBox(height: 10),

              _Tile(
                icon: Icons.palette_outlined,
                title: 'Design',
                subtitle: currentDesignName,
                trailing: const Icon(Icons.chevron_right, size: 24),
                onTap: _openDesignPicker,
              ),

              const SizedBox(height: 18),

              _SectionTitle(title: 'Wartung'),
              const SizedBox(height: 10),

              _Tile(
                icon: Icons.delete_outline,
                title: 'Daten löschen',
                subtitle: 'Setzt alles zurück (z.B. Abgeschlossene Aufgaben & alle Einstellungen)',
                trailing: const Icon(Icons.chevron_right, size: 24),
                onTap: _resetAll,
              ),

              const SizedBox(height: 18),

              _SectionTitle(title: 'Sprachen (später)'),
              const SizedBox(height: 10),

              _Tile(
                icon: Icons.language,
                title: 'Sprache',
                subtitle: 'Deutsch (später umstellbar)',
                trailing: const Icon(Icons.chevron_right, size: 24),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Bald kann man die Sprache ändern!🙂')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// =========================
/// Cremiges Design-Auswahl Menü (BottomSheet)
/// =========================
class _DesignPickerSheet extends StatelessWidget {
  final AppSettingsStore settings;

  const _DesignPickerSheet({required this.settings});

  @override
  Widget build(BuildContext context) {
    final selected = settings.darkTheme;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            16,
            18,
            16,
            24 + MediaQuery.of(context).padding.bottom,
          ),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.50),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: Colors.white.withOpacity(0.10)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.28),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Design auswählen',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...OrbitDarkTheme.values.map((t) {
                final isSelected = t == selected;
                return _DesignOption(
                  title: OrbitTheme.displayName(t),
                  selected: isSelected,
                  onTap: () {
                    settings.setDarkTheme(t);
                    Navigator.pop(context);
                  },
                );
              }).toList(),
              const SizedBox(height: 10),
              Text(
                'Bald mehr Designs 👀',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.white60),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DesignOption extends StatelessWidget {
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _DesignOption({
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