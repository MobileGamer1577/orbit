import 'dart:async';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/orbit_theme.dart';
import '../widgets/orbit_glass_card.dart';
import 'fortnite_season_data.dart';

class FortniteCountdownScreen extends StatefulWidget {
  const FortniteCountdownScreen({super.key});

  @override
  State<FortniteCountdownScreen> createState() =>
      _FortniteCountdownScreenState();
}

class _FortniteCountdownScreenState extends State<FortniteCountdownScreen>
    with TickerProviderStateMixin {
  late Timer _timer;
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();

    _controllers = List.generate(
      fortnitePasses.length,
      (i) => AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 800 + i * 120),
      ),
    );

    _animations = List.generate(fortnitePasses.length, (i) {
      return Tween<double>(
        begin: 0,
        end: fortnitePasses[i].progress.clamp(0.0, 1.0),
      ).animate(CurvedAnimation(
        parent: _controllers[i],
        curve: Curves.easeOutCubic,
      ));
    });

    for (int i = 0; i < fortnitePasses.length; i++) {
      Future.delayed(Duration(milliseconds: i * 100), () {
        if (mounted) _controllers[i].forward();
      });
    }

    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: OrbitBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        l10n.countdownTitle,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  l10n.countdownSubtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.55),
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    itemCount: fortnitePasses.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, i) {
                      return AnimatedBuilder(
                        animation: _animations[i],
                        builder: (context, _) => _PassCard(
                          pass: fortnitePasses[i],
                          animatedProgress: _animations[i].value,
                          l10n: l10n,
                        ),
                      );
                    },
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

class _PassCard extends StatelessWidget {
  final FortnitePassData pass;
  final double animatedProgress;
  final AppLocalizations l10n;

  const _PassCard({
    required this.pass,
    required this.animatedProgress,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final bool expired = now.isAfter(pass.endDate);
    final remaining = pass.endDate.difference(now);
    final totalDays = pass.endDate.difference(pass.startDate).inDays;
    final elapsed = now.difference(pass.startDate).inDays.clamp(0, totalDays);

    Color statusColor;
    String statusText;
    if (expired) {
      statusColor = Colors.red.shade400;
      statusText = l10n.countdownExpired;
    } else if (remaining.inDays <= 3) {
      statusColor = Colors.orange.shade400;
      statusText = l10n.countdownExpiringSoon;
    } else {
      statusColor = pass.color;
      statusText = l10n.countdownActive;
    }

    return OrbitGlassCard(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: pass.color.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: pass.color.withOpacity(0.35),
                      width: 1.2,
                    ),
                  ),
                  child: Icon(pass.icon, color: pass.color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pass.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: statusColor.withOpacity(0.55),
                                  blurRadius: 5,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (!expired)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: pass.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                        color: pass.color.withOpacity(0.35),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${remaining.inDays}',
                          style: TextStyle(
                            color: pass.color,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            height: 1.0,
                          ),
                        ),
                        Text(
                          l10n.countdownDays,
                          style: TextStyle(
                            color: pass.color.withOpacity(0.65),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                          color: Colors.red.withOpacity(0.3), width: 1),
                    ),
                    child: const Icon(Icons.close_rounded,
                        color: Colors.redAccent, size: 20),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: Stack(
                children: [
                  Container(
                    height: 7,
                    color: Colors.white.withOpacity(0.07),
                  ),
                  FractionallySizedBox(
                    widthFactor: animatedProgress,
                    child: Container(
                      height: 7,
                      decoration: BoxDecoration(
                        color: pass.color,
                        borderRadius: BorderRadius.circular(100),
                        boxShadow: [
                          BoxShadow(
                            color: pass.color.withOpacity(0.55),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.countdownDayProgress(elapsed, totalDays),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${(pass.progress * 100).clamp(0, 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: pass.color.withOpacity(0.75),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${_fmt(pass.startDate, l10n)}  →  ${_fmt(pass.endDate, l10n)}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.28),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime d, AppLocalizations l10n) {
    final months = l10n.monthNames;
    return '${d.day.toString().padLeft(2, '0')}. ${months[d.month - 1]} ${d.year}';
  }
}
