import 'dart:async';

import 'package:flutter/material.dart';
import '../theme/orbit_theme.dart';

class FortniteCountdownScreen extends StatefulWidget {
  const FortniteCountdownScreen({super.key});

  @override
  State<FortniteCountdownScreen> createState() => _FortniteCountdownScreenState();
}

class _FortniteCountdownScreenState extends State<FortniteCountdownScreen> {
  late final Timer _timer;

  // 0 = Chapter Season, 1 = OG, 2 = LEGO, 3 = Festival
  int selected = 0;

  @override
  void initState() {
    super.initState();
    // Jede Sekunde neu rendern -> Live Countdown
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  // Du kannst die Daten später easy ändern (Start/Ende).
  // End-Daten sind aus deinen Screenshots übernommen:
  // - Chapter 7 Season 1: 19. März 2026
  // - OG Season 7: 18. März 2026
  // - LEGO Pass: 1. April 2026
  // - Festival: 16. April 2026
  //
  // Start-Daten sind hier "grob" gesetzt, nur damit %/Progress schön aussieht.
  // Wenn du die echten Start-Daten kennst, trag sie hier ein.
  List<_CountdownItem> get _items => [
        _CountdownItem(
          keyId: 'chapter',
          labelShort: 'F',
          title: 'Fortnite Chapter 7 Season 1',
          start: DateTime(2026, 2, 1, 9, 0),
          end: DateTime(2026, 3, 19, 9, 0),
        ),
        _CountdownItem(
          keyId: 'og',
          labelShort: 'OG',
          title: 'Fortnite OG Season 7',
          start: DateTime(2026, 2, 1, 9, 0),
          end: DateTime(2026, 3, 18, 9, 0),
        ),
        _CountdownItem(
          keyId: 'lego',
          labelShort: 'LEGO',
          title: 'Fortnite LEGO Pass',
          start: DateTime(2026, 2, 10, 9, 0),
          end: DateTime(2026, 4, 1, 9, 0),
        ),
        _CountdownItem(
          keyId: 'festival',
          labelShort: 'FEST',
          title: 'Fortnite Festival',
          start: DateTime(2026, 2, 1, 9, 0),
          end: DateTime(2026, 4, 16, 9, 0),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final item = _items[selected];

    final total = item.end.difference(item.start);
    final elapsed = now.difference(item.start);
    final progress = total.inSeconds <= 0
        ? 0.0
        : (elapsed.inSeconds / total.inSeconds).clamp(0.0, 1.0);

    final remaining = item.end.difference(now);
    final isEnded = remaining.inSeconds <= 0;

    final remainingAbs = isEnded ? Duration.zero : remaining;

    final daysRemaining = remainingAbs.inDays;
    final percent = (progress * 100).round();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: OrbitBackground(
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
                    Text(
                      'Season Countdown',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Tabs oben wie in deinen Bildern (kleine runde Buttons)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_items.length, (i) {
                    final active = i == selected;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: _MiniTab(
                        text: _items[i].labelShort,
                        active: active,
                        onTap: () => setState(() => selected = i),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 18),

                // Headline
                Text(
                  'When does ${item.title} end?',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                ),

                const SizedBox(height: 10),

                // Subtitle mit % + Tage
                Text(
                  isEnded
                      ? 'Ended.'
                      : '${item.title} is $percent% complete. There are $daysRemaining days remaining.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                ),

                const SizedBox(height: 12),

                // Progress Bar (dünn)
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: isEnded ? 1.0 : progress,
                    minHeight: 10,
                    backgroundColor: Colors.black.withOpacity(0.35),
                  ),
                ),

                const SizedBox(height: 18),

                // Big Countdown Box
                _BigCountdownBox(
                  text: isEnded ? '00 : 00 : 00 : 00' : _formatDDHHMMSS(remainingAbs),
                ),

                const SizedBox(height: 18),

                // Bottom Infos
                _BottomInfo(
                  end: item.end,
                  nextLine: _buildNextSeasonLine(item),
                ),

                const Spacer(),

                // Optional: kleiner Hinweis (kannst du später entfernen)
                Text(
                  'Tipp: Wenn du echte Start-Daten einträgst, passt auch die % Anzeige perfekt.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white38,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _buildNextSeasonLine(_CountdownItem item) {
    // Nur als Platzhalter, damit es wie auf den Bildern aussieht.
    // Später können wir das pro Item korrekt machen.
    return 'Next content starts on the same day.';
  }

  String _formatDDHHMMSS(Duration d) {
    final totalSeconds = d.inSeconds;
    final dd = totalSeconds ~/ 86400;
    final hh = (totalSeconds % 86400) ~/ 3600;
    final mm = (totalSeconds % 3600) ~/ 60;
    final ss = totalSeconds % 60;

    String two(int v) => v.toString().padLeft(2, '0');
    // DD darf ruhig auch 1-3 Stellen haben
    final ddStr = dd.toString().padLeft(2, '0');

    return '$ddStr : ${two(hh)} : ${two(mm)} : ${two(ss)}';
  }
}

class _CountdownItem {
  final String keyId;
  final String labelShort;
  final String title;
  final DateTime start;
  final DateTime end;

  const _CountdownItem({
    required this.keyId,
    required this.labelShort,
    required this.title,
    required this.start,
    required this.end,
  });
}

class _MiniTab extends StatelessWidget {
  final String text;
  final bool active;
  final VoidCallback onTap;

  const _MiniTab({
    required this.text,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Ink(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? Colors.white.withOpacity(0.14) : Colors.white.withOpacity(0.06),
          border: Border.all(
            color: active ? Colors.white.withOpacity(0.35) : Colors.white.withOpacity(0.12),
          ),
        ),
        child: Center(
          child: Text(
            text,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
        ),
      ),
    );
  }
}

class _BigCountdownBox extends StatelessWidget {
  final String text;

  const _BigCountdownBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.28),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFFFD400), // gelb
          width: 3,
        ),
      ),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: const Color(0xFFFFD400),
                letterSpacing: 2,
              ),
        ),
      ),
    );
  }
}

class _BottomInfo extends StatelessWidget {
  final DateTime end;
  final String nextLine;

  const _BottomInfo({required this.end, required this.nextLine});

  @override
  Widget build(BuildContext context) {
    final endStr = _formatPretty(end);

    return Column(
      children: [
        Text(
          'Ends on $endStr.',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          nextLine,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
                fontWeight: FontWeight.w700,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  static String _formatPretty(DateTime dt) {
    const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];

    final wd = weekdays[dt.weekday - 1];
    final m = months[dt.month - 1];
    return '$wd, $m ${dt.day}, ${dt.year}';
  }
}