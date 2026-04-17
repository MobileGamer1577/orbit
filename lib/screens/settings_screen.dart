import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../services/update_service.dart';
import '../storage/app_settings_store.dart';
import '../storage/quest_cache_store.dart'; // ← NEU: Quest-Cache
import '../storage/update_store.dart';
import '../theme/orbit_theme.dart';
import 'dev_screen.dart';

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

  // ── DEV MODE TAP SYSTEM ────────────────────────────────────
  int _devTapCount = 0;
  final int _devTapTarget = 8;
  DateTime? _lastTapTime;

  void _onVersionTap() {
    final now = DateTime.now();
    if (_lastTapTime != null &&
        now.difference(_lastTapTime!).inMilliseconds > 2000) {
      _devTapCount = 0;
    }
    _lastTapTime = now;
    _devTapCount++;

    final remaining = _devTapTarget - _devTapCount;
    if (_devTapCount >= 4 && remaining > 0) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Noch $remaining Taps…'),
          duration: const Duration(milliseconds: 800),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    if (_devTapCount >= _devTapTarget) {
      _devTapCount = 0;
      _lastTapTime = null;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DevScreen()),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _loadVersion();
    widget.settings.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    widget.settings.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() => setState(() {});

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() => _versionText = '${info.version}+${info.buildNumber}');
  }

  Future<void> _checkUpdates() async {
    if (_checking) return;
    setState(() => _checking = true);
    final l10n = context.l10n;
    try {
      final result = await UpdateService.checkForUpdates();
      if (!mounted) return;
      if (result.updateAvailable) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.updateAvailableTitle(result.latest)} 🚀'),
          ),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.updateNoUpdate)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.updateFailed)));
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
          SnackBar(content: Text(context.l10n.updateGithubFailed)),
        );
      }
    }
  }

  Future<void> _resetTasks() async {
    final box = await Hive.openBox('task_state');
    await box.clear();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.resetProgressDone)));
  }

  // ── NEU: Quest-Cache leeren ────────────────────────────────
  Future<void> _clearQuestCache() async {
    await QuestCacheStore.clearAll();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Quest-Cache geleert ✅ — beim nächsten Öffnen neu laden'),
      ),
    );
  }

  Future<void> _showLanguagePicker() async {
    final current = widget.settings.language;
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _LanguageSheet(
        currentLanguage: current,
        onSelected: (lang) async {
          await widget.settings.setLanguage(lang);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    final String updateSubtitle;
    if (widget.updateStore.isChecking) {
      updateSubtitle = l10n.updateChecking;
    } else if (widget.updateStore.updateAvailable) {
      updateSubtitle = l10n.updateAvailableTitle(widget.updateStore.latest);
    } else {
      updateSubtitle = l10n.updateCurrent;
    }

    final lang = widget.settings.language;
    final langLabel = lang == 'de' ? '🇩🇪  Deutsch' : '🇬🇧  English';

    return OrbitBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            l10n.settingsTitle,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
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
                _SectionTitle(title: l10n.sectionGeneral),
                const SizedBox(height: 10),
                _Tile(
                  icon: Icons.info_outline,
                  iconColor: const Color(0xFF9C6FFF),
                  title: l10n.version,
                  subtitle: _versionText,
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: Colors.white24,
                  ),
                  onTap: _onVersionTap,
                ),
                const SizedBox(height: 10),
                _Tile(
                  icon: Icons.language,
                  iconColor: const Color(0xFF4CAF50),
                  title: l10n.languageLabel,
                  subtitle: langLabel,
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: Colors.white24,
                  ),
                  onTap: _showLanguagePicker,
                ),

                // ── Updates ────────────────────────────────
                const SizedBox(height: 22),
                _SectionTitle(title: l10n.sectionUpdates),
                const SizedBox(height: 10),
                _Tile(
                  icon: Icons.system_update_alt,
                  iconColor: const Color(0xFF00D4FF),
                  title: l10n.updateStatus,
                  subtitle: updateSubtitle,
                  trailing: _checking
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.chevron_right, color: Colors.white24),
                  onTap: _checkUpdates,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _ActionBtn(
                        icon: Icons.refresh,
                        label: l10n.updateCheckBtn,
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
                _SectionTitle(title: l10n.sectionReset),
                const SizedBox(height: 10),
                _Tile(
                  icon: Icons.restart_alt,
                  iconColor: const Color(0xFFFF6B6B),
                  title: l10n.resetProgress,
                  subtitle: l10n.resetProgressSubtitle,
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: Colors.white24,
                  ),
                  onTap: _resetTasks,
                ),

                // ── NEU: Quest-Cache ───────────────────────
                const SizedBox(height: 10),
                _Tile(
                  icon: Icons.cloud_off_rounded,
                  iconColor: const Color(0xFFFF8C00),
                  title: 'Quest-Cache leeren',
                  subtitle: 'Erzwingt Neu-Download der Quests von der API',
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: Colors.white24,
                  ),
                  onTap: _clearQuestCache,
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
//  Sprach-Auswahl Sheet
// ──────────────────────────────────────────────────────────────

class _LanguageSheet extends StatelessWidget {
  final String currentLanguage;
  final void Function(String) onSelected;

  const _LanguageSheet({
    required this.currentLanguage,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final options = [
      {'code': 'de', 'flag': '🇩🇪', 'label': 'Deutsch'},
      {'code': 'en', 'flag': '🇬🇧', 'label': 'English'},
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withOpacity(0.11),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          Text(
            l10n.languageLabel,
            style: TextStyle(
              color: Colors.white.withOpacity(0.55),
              fontWeight: FontWeight.w700,
              fontSize: 13,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          const Divider(color: Colors.white12, height: 1),
          ...options.map((opt) {
            final isSelected = opt['code'] == currentLanguage;
            return InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                onSelected(opt['code']!);
                Navigator.pop(context);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    Text(opt['flag']!, style: const TextStyle(fontSize: 26)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        opt['label']!,
                        style: TextStyle(
                          color: isSelected
                              ? const Color(0xFF4CAF50)
                              : Colors.white,
                          fontWeight: isSelected
                              ? FontWeight.w800
                              : FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    if (isSelected)
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF4CAF50),
                        size: 22,
                      ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  Wiederverwendbare Bausteine
// ──────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) => Text(
    title.toUpperCase(),
    style: TextStyle(
      color: Colors.white.withOpacity(0.40),
      fontWeight: FontWeight.w700,
      fontSize: 11,
      letterSpacing: 1.5,
    ),
  );
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
  Widget build(BuildContext context) => Material(
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
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onPressed,
    style: OutlinedButton.styleFrom(
      foregroundColor: Colors.white,
      backgroundColor: accent
          ? Colors.white.withOpacity(0.08)
          : Colors.transparent,
      padding: const EdgeInsets.symmetric(vertical: 13),
      side: BorderSide(color: Colors.white.withOpacity(accent ? 0.18 : 0.14)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    icon: Icon(icon, size: 17),
    label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
  );
}
