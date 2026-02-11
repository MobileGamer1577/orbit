import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../storage/app_settings_store.dart';
import '../theme/orbit_theme.dart';

class SettingsScreen extends StatefulWidget {
  final AppSettingsStore settings;

  const SettingsScreen({super.key, required this.settings});

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
    setState(() => _versionText = '${info.version}+${info.buildNumber}');
  }

  Future<void> _openDesignPicker() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.45), // macht unten dunkler
      isScrollControlled: true,
      builder: (_) => _DesignPickerSheet(settings: widget.settings),
    );

    // wenn du nach dem Schließen nochmal neu zeichnen willst:
    if (mounted) setState(() {});
  }

  Future<void> _resetAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Alles zurücksetzen?'),
        content: const Text(
          'Das setzt alles zurück (z.B. Häkchen und gespeicherte Einstellungen).',
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

  @override
  Widget build(BuildContext context) {
    final currentDesignName = OrbitTheme.displayName(widget.settings.darkTheme);

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

              // ✅ Design auswählen (statt "Design-Modus" + extra Dark-Button)
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
                subtitle: 'Setzt alles zurück (z.B. Häkchen & Einstellungen)',
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
                    const SnackBar(
                      content: Text('Sprache bauen wir als nächstes rein 🙂'),
                    ),
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
            color: Colors.black.withOpacity(0.50), // "cremig"
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: Colors.white.withOpacity(0.10)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
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
            if (selected)
              const Icon(Icons.check_circle, color: Colors.white),
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