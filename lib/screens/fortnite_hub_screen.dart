import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/orbit_theme.dart';
import 'mode_select_screen.dart';

class FortniteHubScreen extends StatelessWidget {
  const FortniteHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: OrbitBackground(
        child: SizedBox.expand(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Bar
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Fortnite',
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

                  const SizedBox(height: 10),
                  Text(
                    'Wähle einen Bereich',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 14),

                  Expanded(
                    child: ListView.separated(
                      itemCount: 3,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        if (i == 0) {
                          // Aufgaben
                          return _HubCard(
                            icon: Icons.checklist_rounded,
                            title: 'Aufgaben',
                            subtitle:
                                'Modus auswählen (BR, Reload, OG …) und Aufgaben abhaken',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ModeSelectScreen(
                                    gameId: 'fortnite',
                                    gameTitle: 'Fortnite – Aufgaben',
                                  ),
                                ),
                              );
                            },
                          );
                        }

                        if (i == 1) {
                          // Season Countdown
                          return _HubCard(
                            icon: Icons.timer_outlined,
                            title: 'Season Countdown',
                            subtitle:
                                'Sieh live, wann die Seasons/Passes enden (Echtzeit)',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const FortniteSeasonCountdownScreen(),
                                ),
                              );
                            },
                          );
                        }

                        // Shop
                        return _HubCard(
                          icon: Icons.shopping_bag_outlined,
                          title: 'Item-Shop',
                          subtitle:
                              'Bald verfügbar – bis dahin offizieller Web-Shop',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const FortniteShopPlaceholderScreen(),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HubCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _HubCard({
    required this.icon,
    required this.title,
    required this.subtitle,
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
            Icon(icon, size: 26),
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
                        ?.copyWith(fontWeight: FontWeight.w800),
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
            const Icon(Icons.chevron_right, size: 28),
          ],
        ),
      ),
    );
  }
}

/// =========================
/// Fortnite Season Countdown
/// =========================

enum _FortniteCountdownKind { br, og, lego, festival }

class _FortniteCountdownData {
  final _FortniteCountdownKind kind;

  final String title;
  final String shortLabel;
  final IconData icon;

  final String detailQuestion;
  final String detailSubtitle;

  final DateTime startsAt;
  final DateTime endsAt;

  const _FortniteCountdownData({
    required this.kind,
    required this.title,
    required this.shortLabel,
    required this.icon,
    required this.detailQuestion,
    required this.detailSubtitle,
    required this.startsAt,
    required this.endsAt,
  });
}

class FortniteSeasonCountdownScreen extends StatefulWidget {
  const FortniteSeasonCountdownScreen({super.key});

  @override
  State<FortniteSeasonCountdownScreen> createState() =>
      _FortniteSeasonCountdownScreenState();
}

class _FortniteSeasonCountdownScreenState
    extends State<FortniteSeasonCountdownScreen> {
  Timer? _timer;
  DateTime _now = DateTime.now();

  late final List<_FortniteCountdownData> _items = [
    _FortniteCountdownData(
      kind: _FortniteCountdownKind.br,
      title: 'Battle Royale – Kapitel 7 Season 1',
      shortLabel: 'BR',
      icon: Icons.sports_esports,
      detailQuestion: 'Wann endet Battle Royale?',
      detailSubtitle: 'Kapitel 7 – Season 1',
      startsAt: DateTime(2025, 11, 30, 1, 30),
      endsAt: DateTime(2026, 3, 19, 10, 0),
    ),
    _FortniteCountdownData(
      kind: _FortniteCountdownKind.og,
      title: 'Fortnite OG – Kapitel 1 Season 7',
      shortLabel: 'OG',
      icon: Icons.history,
      detailQuestion: 'Wann endet Fortnite OG?',
      detailSubtitle: 'Kapitel 1 – Season 7',
      startsAt: DateTime(2025, 12, 11, 14, 0),
      endsAt: DateTime(2026, 3, 18, 10, 0),
    ),
    _FortniteCountdownData(
      kind: _FortniteCountdownKind.lego,
      title: 'LEGO® Fortnite – LEGO® Pass',
      shortLabel: 'LEGO',
      icon: Icons.extension,
      detailQuestion: 'Wann endet LEGO Pass?',
      detailSubtitle: 'LEGO Pass',
      startsAt: DateTime(2025, 12, 11, 14, 0),
      endsAt: DateTime(2026, 4, 1, 10, 0),
    ),
    _FortniteCountdownData(
      kind: _FortniteCountdownKind.festival,
      title: 'Fortnite Festival',
      shortLabel: 'FEST',
      icon: Icons.music_note,
      detailQuestion: 'Wann endet Fortnite Festival?',
      detailSubtitle: 'Festival',
      startsAt: DateTime(2026, 2, 5, 12, 0),
      endsAt: DateTime(2026, 4, 16, 11, 0),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  String _formatDateTime(DateTime dt) {
    final d = _two(dt.day);
    final m = _two(dt.month);
    final y = dt.year;
    final h = _two(dt.hour);
    final min = _two(dt.minute);
    return '$d.$m.$y  $h:$min Uhr';
  }

  double _progress(DateTime now, DateTime start, DateTime end) {
    final total = end.difference(start).inMilliseconds;
    final done = now.difference(start).inMilliseconds;
    if (total <= 0) return 0;
    final p = done / total;
    if (p.isNaN) return 0;
    return p.clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: OrbitBackground(
        child: SizedBox.expand(
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
                        'Fortnite – Season Countdown',
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
                const SizedBox(height: 10),
                Text(
                  'Live-Countdowns',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 14),

                ..._items.map((it) {
                  final p = _progress(_now, it.startsAt, it.endsAt);
                  final left = it.endsAt.difference(_now);
                  final leftSafe = left.isNegative ? Duration.zero : left;
                  final days = leftSafe.inDays;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _CountdownPreviewCard(
                      icon: it.icon,
                      title: it.title,
                      startsAt: _formatDateTime(it.startsAt),
                      endsAt: _formatDateTime(it.endsAt),
                      progress: p,
                      progressText:
                          '${(p * 100).toStringAsFixed(1)}% abgeschlossen',
                      remainingText: '$days Tage übrig',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FortniteSeasonCountdownDetailScreen(
                              data: it,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }).toList(),

                const SizedBox(height: 6),
                Text(
                  'Die Zeiten basieren auf offiziellen Angaben von Epic Games und werden automatisch aktualisiert.',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.white54),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CountdownPreviewCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String startsAt;
  final String endsAt;

  final double progress;
  final String progressText;
  final String remainingText;

  final VoidCallback onTap;

  const _CountdownPreviewCard({
    required this.icon,
    required this.title,
    required this.startsAt,
    required this.endsAt,
    required this.progress,
    required this.progressText,
    required this.remainingText,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 22, color: Colors.white.withOpacity(0.9)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                const Icon(Icons.chevron_right, size: 24),
              ],
            ),
            const SizedBox(height: 12),

            _kv(context, 'Season läuft seit', startsAt),
            const SizedBox(height: 6),
            _kv(context, 'Season läuft bis', endsAt),

            const SizedBox(height: 14),

            Row(
              children: [
                Text(
                  progressText,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.white70),
                ),
                const Spacer(),
                Text(
                  remainingText,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.white70),
                ),
              ],
            ),
            const SizedBox(height: 8),

            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: Colors.white.withOpacity(0.10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kv(BuildContext context, String k, String v) {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: Text(
            k,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.white60),
          ),
        ),
        Expanded(
          flex: 7,
          child: Text(
            v,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.white.withOpacity(0.9)),
          ),
        ),
      ],
    );
  }
}

/// =========================
/// Countdown Detail (cleaner)
/// =========================
class FortniteSeasonCountdownDetailScreen extends StatefulWidget {
  final _FortniteCountdownData data;

  const FortniteSeasonCountdownDetailScreen({super.key, required this.data});

  @override
  State<FortniteSeasonCountdownDetailScreen> createState() =>
      _FortniteSeasonCountdownDetailScreenState();
}

class _FortniteSeasonCountdownDetailScreenState
    extends State<FortniteSeasonCountdownDetailScreen> {
  Timer? _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  String _formatDateTime(DateTime dt) {
    final d = _two(dt.day);
    final m = _two(dt.month);
    final y = dt.year;
    final h = _two(dt.hour);
    final min = _two(dt.minute);
    return '$d.$m.$y  $h:$min Uhr';
  }

  double _progress(DateTime now, DateTime start, DateTime end) {
    final total = end.difference(start).inMilliseconds;
    final done = now.difference(start).inMilliseconds;
    if (total <= 0) return 0;
    final p = done / total;
    if (p.isNaN) return 0;
    return p.clamp(0.0, 1.0);
  }

  String _formatLeft(Duration d) {
    if (d.isNegative) return '0s';
    final days = d.inDays;
    final hours = d.inHours.remainder(24);
    final mins = d.inMinutes.remainder(60);
    final secs = d.inSeconds.remainder(60);
    return '${days}d ${hours}h ${mins}m ${secs}s';
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.data;

    final p = _progress(_now, item.startsAt, item.endsAt);
    final left = item.endsAt.difference(_now);
    final leftSafe = left.isNegative ? Duration.zero : left;
    final days = leftSafe.inDays;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: OrbitBackground(
        child: SizedBox.expand(
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
                        'Fortnite – Season Countdown',
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
                const SizedBox(height: 18),

                Text(
                  item.detailQuestion,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 10),

                Text(
                  item.detailSubtitle,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 14),

                Text(
                  '${(p * 100).toStringAsFixed(1)}% abgeschlossen • $days Tage übrig',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 10),

                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: p,
                    minHeight: 10,
                    backgroundColor: Colors.white.withOpacity(0.10),
                  ),
                ),

                const SizedBox(height: 14),

                // Kleiner Live-Text statt riesiger Box (wirkt cleaner)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.timer_outlined,
                          size: 20, color: Colors.white70),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Verbleibend: ${_formatLeft(leftSafe)}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                _InfoCard(
                  title: 'Season läuft seit',
                  value: _formatDateTime(item.startsAt),
                ),
                const SizedBox(height: 10),
                _InfoCard(
                  title: 'Season läuft bis',
                  value: _formatDateTime(item.endsAt),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String value;

  const _InfoCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          const Icon(Icons.event, size: 20, color: Colors.white70),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.white60),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// -------------------------
/// Shop Placeholder (Link öffnen)
/// -------------------------
class FortniteShopPlaceholderScreen extends StatelessWidget {
  const FortniteShopPlaceholderScreen({super.key});

  static const shopUrl = 'https://www.fortnite.com/item-shop?lang=en';

  Future<void> _openShop(BuildContext context) async {
    final uri = Uri.parse(shopUrl);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konnte den Link nicht öffnen.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: OrbitBackground(
        child: SizedBox.expand(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
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
                          'Fortnite – Item-Shop',
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

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bald verfügbar 🚧',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Bis dahin kannst du den offiziellen Web-Shop nutzen:',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: Colors.white70),
                        ),
                        const SizedBox(height: 10),

                        // weiterhin sichtbar/kopierbar
                        SelectableText(
                          shopUrl,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                decoration: TextDecoration.underline,
                              ),
                        ),

                        const SizedBox(height: 12),

                        // ✅ wirklich öffnen
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _openShop(context),
                            icon: const Icon(Icons.open_in_new),
                            label: const Text('Im Browser öffnen'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}