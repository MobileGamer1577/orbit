import 'package:flutter/material.dart';

import '../config/game_registry.dart';
import '../l10n/app_localizations.dart';
import '../theme/orbit_theme.dart';
import '../widgets/orbit_glass_card.dart';

import 'task_list_screen.dart';
import 'eos_quest_test_screen.dart';

class ModeSelectScreen extends StatelessWidget {
  final String gameId;
  final String gameTitle;

  const ModeSelectScreen({
    super.key,
    required this.gameId,
    required this.gameTitle,
  });

  @override
  Widget build(BuildContext context) {
    final l10n  = context.l10n;
    final modes = GameRegistry.modesFor(gameId);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: OrbitBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ─────────────────────────────────
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.arrow_back,
                        color: Colors.white.withOpacity(0.90),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        gameTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Text(
                    l10n.modeSelectSubtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.50),
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    children: [

                      // ── EOS Test-Button (nur bei Fortnite) ──
                      if (gameId == 'fortnite') ...[
                        _TestCard(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const EosQuestTestScreen(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Trenner
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 1,
                                color: Colors.white.withOpacity(0.08),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'MODI',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.30),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 1,
                                color: Colors.white.withOpacity(0.08),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                      ],

                      // ── Normale Modus-Karten ─────────────
                      ...modes.asMap().entries.map((e) {
                        final i    = e.key;
                        final mode = e.value;
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: i < modes.length - 1 ? 10 : 0,
                          ),
                          child: _ModeCard(
                            icon:      mode.icon,
                            iconColor: mode.color,
                            title:     mode.title,
                            subtitle:  mode.subtitle,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TaskListScreen(
                                  title:         '$gameTitle – ${mode.title}',
                                  jsonAssetPath: mode.assetPath,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
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

// ──────────────────────────────────────────────────────────────
//  Test-Karte — hebt sich visuell von normalen Modi ab
// ──────────────────────────────────────────────────────────────

class _TestCard extends StatelessWidget {
  final VoidCallback onTap;
  const _TestCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF9C6FFF).withOpacity(0.18),
              const Color(0xFF00D4FF).withOpacity(0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF9C6FFF).withOpacity(0.50),
            width: 1.3,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF9C6FFF).withOpacity(0.20),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                  color: const Color(0xFF9C6FFF).withOpacity(0.55),
                  width: 1.2,
                ),
              ),
              child: const Center(
                child: Text('🧪', style: TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'EOS Quest API Test',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Neue EpicGames EOS-Service API testen',
                    style: TextStyle(
                      color: const Color(0xFF9C6FFF).withOpacity(0.80),
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.white.withOpacity(0.35),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  _ModeCard
// ──────────────────────────────────────────────────────────────

class _ModeCard extends StatelessWidget {
  final IconData     icon;
  final Color        iconColor;
  final String       title;
  final String       subtitle;
  final VoidCallback onTap;

  const _ModeCard({
    required this.icon,
    required this.iconColor,
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
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: iconColor.withOpacity(0.30),
                    width: 1.2,
                  ),
                ),
                child: Icon(icon, color: iconColor, size: 22),
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
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.55),
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.white.withOpacity(0.35),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
