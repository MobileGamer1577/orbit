import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../theme/orbit_theme.dart';
import '../widgets/orbit_glass_card.dart';
import 'fortnite_season_data.dart'; // Season-Daten für Fortschrittsanzeige

// ══════════════════════════════════════════════════════════════
//
//  🧮 XP CALCULATOR SCREEN
//  Datei: lib/screens/fortnite_xp_calculator_screen.dart
//
//  Features:
//    1. Season-Fortschrittsanzeige (animierter Balken Blau ↔ Lila)
//    2. XP-Rechner: Aktuelles Level + Wunsch-Level → tägliche XP
//    3. Spielzeit-XP Tabelle (XP/Minute pro Modus + wöchentl. Limit)
//
//  ✏️  XP-WERTE ANPASSEN (kein Umbau nötig):
//    → _kXpTiers       : XP pro Level nach Stufe (z.B. nach Season-Änderung)
//    → _kPlaytimeModes : XP/Minute + wöchentliches Limit pro Modus
//
// ══════════════════════════════════════════════════════════════

// ── XP PER LEVEL (Stufen-System) ───────────────────────────────
//
// ✏️  HIER anpassen wenn Fortnite die Level-XP-Werte ändert:
//   Format: (maximales Level dieser Stufe, XP pro Level)
//   Beispiel: Level 1–100 kosten je 80.000 XP
//
const List<(int, int)> _kXpTiers = [
  (100, 80000), // Level    1–100:  80.000 XP pro Level
  (20000, 80000), // Level  101–200:  80.000 XP pro Level
  (30000, 100000), // Level  201–300: 100.000 XP pro Level
  (40000, 110000), // Level  301–400: 110.000 XP pro Level
  (50000, 120000), // Level  401–500: 120.000 XP pro Level
  (60000, 130000), // Level  501–600: 130.000 XP pro Level
  (70000, 140000), // Level  601–700: 140.000 XP pro Level
  (80000, 150000), // Level  701–800: 150.000 XP pro Level
  (90000, 160000), // Level 801–900:   160.000 XP pro Level
];

// ── SPIELZEIT-XP ───────────────────────────────────────────────
//
// ✏️  HIER anpassen wenn Fortnite die Spielzeit-XP-Werte ändert:
//   Format: (Modus-Name, XP pro Minute, wöchentl. Limit in XP)
//   Limit = 0 bedeutet: kein wöchentliches Limit
//
const List<(String, int, int)> _kPlaytimeModes = [
  ('Battle Royale', 350, 4000000),
  ('Reload', 2000, 4000000),
  ('Blitz Royale', 850, 4000000),
  ('Ballistic', 2400, 4000000),
  ('OG', 950, 4000000),
  ('LEGO Odyssey', 2700, 4000000),
  ('LEGO Brick Life', 2750, 4000000),
  ('Festival Main Stage', 1050, 4000000),
  ('Festival Jam Stage', 2850, 4000000),
  ('Creative', 2850, 0), // ← kein wöchentliches Limit
];

// ══════════════════════════════════════════════════════════════
//  SCREEN
// ══════════════════════════════════════════════════════════════

class FortniteXpCalculatorScreen extends StatefulWidget {
  const FortniteXpCalculatorScreen({super.key});

  @override
  State<FortniteXpCalculatorScreen> createState() =>
      _FortniteXpCalculatorScreenState();
}

class _FortniteXpCalculatorScreenState extends State<FortniteXpCalculatorScreen>
    with SingleTickerProviderStateMixin {
  // ── Animation: Blau ↔ Lila für den Season-Fortschrittsbalken ──
  late final AnimationController _barCtrl;
  late final Animation<Color?> _barColor;

  // ── XP-Rechner Eingabefelder ───────────────────────────────
  final _currentCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();

  // ── Berechnungsergebnis ────────────────────────────────────
  String? _dailyXpResult; // z.B. "97.561"
  String? _totalXpResult; // z.B. "2.926.830"
  String? _calcError; // Fehlermeldung wenn Eingabe ungültig

  // ── Season-Daten aus fortnite_season_data.dart ─────────────
  late final FortnitePassData _battlePass;
  late final int _seasonPercent; // 0–100
  late final int _daysRemaining; // verbleibende Tage

  // ──────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();

    // Animierter Farbwechsel: Blau ↔ Lila (smooth loop)
    _barCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _barColor = ColorTween(
      begin: const Color(0xFF00D4FF), // Blau
      end: const Color(0xFF7C4DFF), // Lila
    ).animate(CurvedAnimation(parent: _barCtrl, curve: Curves.easeInOut));

    // Battle Pass aus fortnite_season_data.dart laden
    // (erster Eintrag mit dem Namen 'Battle Pass', Fallback: erster Eintrag)
    _battlePass = fortnitePasses.firstWhere(
      (p) => p.name == 'Battle Pass',
      orElse: () => fortnitePasses.first,
    );

    _seasonPercent = (_battlePass.progress * 100).round().clamp(0, 100);
    final remaining = _battlePass.endDate.difference(DateTime.now());
    _daysRemaining = remaining.inDays.clamp(0, 9999);
  }

  @override
  void dispose() {
    _barCtrl.dispose();
    _currentCtrl.dispose();
    _targetCtrl.dispose();
    super.dispose();
  }

  // ── XP-Berechnung ──────────────────────────────────────────

  /// Kumulierte XP von Level 0 bis `level` (exklusiv Level 0).
  static int _cumulativeXp(int level) {
    if (level <= 0) return 0;
    int total = 0;
    int prev = 0;
    for (final (max, xpPerLvl) in _kXpTiers) {
      final cap = math.min(level, max);
      total += (cap - prev) * xpPerLvl;
      prev = max;
      if (level <= max) break;
    }
    return total;
  }

  /// Formatiert eine Zahl mit Punkt als Tausender-Trenner.
  /// Beispiel: 97561 → "97.561"
  static String _fmtNum(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  /// Löst die Berechnung aus und aktualisiert den State.
  void _calculate() {
    final cur = int.tryParse(_currentCtrl.text.trim());
    final tgt = int.tryParse(_targetCtrl.text.trim());

    // Eingabe-Validierung
    if (cur == null || tgt == null) {
      setState(() {
        _calcError = 'Bitte gültige Level eingeben (nur Zahlen).';
        _dailyXpResult = null;
        _totalXpResult = null;
      });
      return;
    }
    if (cur < 1 || cur > 3400) {
      setState(() {
        _calcError = 'Aktuelles Level muss zwischen 1 und 3400 liegen.';
        _dailyXpResult = null;
        _totalXpResult = null;
      });
      return;
    }
    if (tgt < 1 || tgt > 3400) {
      setState(() {
        _calcError = 'Wunsch-Level muss zwischen 1 und 3400 liegen.';
        _dailyXpResult = null;
        _totalXpResult = null;
      });
      return;
    }
    if (tgt <= cur) {
      setState(() {
        _calcError = 'Wunsch-Level muss größer als das aktuelle Level sein.';
        _dailyXpResult = null;
        _totalXpResult = null;
      });
      return;
    }
    if (_daysRemaining <= 0) {
      setState(() {
        _calcError = 'Die aktuelle Season ist bereits beendet.';
        _dailyXpResult = null;
        _totalXpResult = null;
      });
      return;
    }

    final needed = _cumulativeXp(tgt) - _cumulativeXp(cur);
    final daily = (needed / _daysRemaining).ceil();

    setState(() {
      _calcError = null;
      _totalXpResult = _fmtNum(needed);
      _dailyXpResult = _fmtNum(daily);
    });
  }

  // ── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: OrbitBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
                child: Row(
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
                        l10n.guidesXpCalc,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                  children: [
                    // ── 1. Season-Fortschritt ────────────────
                    _SeasonProgressCard(
                      percent: _seasonPercent,
                      daysLeft: _daysRemaining,
                      progress: _battlePass.progress,
                      barColorAnim: _barColor,
                      l10n: l10n,
                    ),
                    const SizedBox(height: 16),

                    // ── 2. XP-Rechner ────────────────────────
                    _XpCalculatorCard(
                      currentCtrl: _currentCtrl,
                      targetCtrl: _targetCtrl,
                      onCalculate: _calculate,
                      dailyXpResult: _dailyXpResult,
                      totalXpResult: _totalXpResult,
                      error: _calcError,
                      l10n: l10n,
                    ),
                    const SizedBox(height: 16),

                    // ── 3. Spielzeit-XP ──────────────────────
                    _PlaytimeXpSection(l10n: l10n),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  _SeasonProgressCard
// ══════════════════════════════════════════════════════════════

class _SeasonProgressCard extends StatelessWidget {
  final int percent;
  final int daysLeft;
  final double progress;
  final Animation<Color?> barColorAnim;
  final AppLocalizations l10n;

  const _SeasonProgressCard({
    required this.percent,
    required this.daysLeft,
    required this.progress,
    required this.barColorAnim,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return OrbitGlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info-Text
          Text(
            l10n.xpCalcSeasonInfo(percent, daysLeft),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),

          // Animierter Fortschrittsbalken
          AnimatedBuilder(
            animation: barColorAnim,
            builder: (_, __) => Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 10,
                    backgroundColor: Colors.white.withOpacity(0.10),
                    valueColor: AlwaysStoppedAnimation(
                      barColorAnim.value ?? const Color(0xFF7C4DFF),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Battle Pass',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.45),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '$percent%',
                      style: TextStyle(
                        color: barColorAnim.value ?? const Color(0xFF7C4DFF),
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  _XpCalculatorCard
// ══════════════════════════════════════════════════════════════

class _XpCalculatorCard extends StatelessWidget {
  final TextEditingController currentCtrl;
  final TextEditingController targetCtrl;
  final VoidCallback onCalculate;
  final String? dailyXpResult;
  final String? totalXpResult;
  final String? error;
  final AppLocalizations l10n;

  const _XpCalculatorCard({
    required this.currentCtrl,
    required this.targetCtrl,
    required this.onCalculate,
    required this.dailyXpResult,
    required this.totalXpResult,
    required this.error,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return OrbitGlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titel
          Text(
            'XP Rechner',
            style: TextStyle(
              color: Colors.white.withOpacity(0.40),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 14),

          // Eingabefelder nebeneinander
          Row(
            children: [
              Expanded(
                child: _LevelInput(
                  controller: currentCtrl,
                  label: l10n.xpCalcCurrentLevel,
                  hint: '1',
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.arrow_forward,
                color: Colors.white.withOpacity(0.35),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _LevelInput(
                  controller: targetCtrl,
                  label: l10n.xpCalcTargetLevel,
                  hint: '100',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Berechnen-Button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onCalculate,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF7C4DFF),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.calculate_outlined, size: 18),
              label: Text(
                l10n.xpCalcCalculate,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ),
          ),

          // Fehlermeldung
          if (error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.redAccent.withOpacity(0.35)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.redAccent,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      error!,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Ergebnis
          if (dailyXpResult != null && totalXpResult != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF9C6FFF).withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFF9C6FFF).withOpacity(0.40),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tägliche XP — Hauptergebnis
                  Text(
                    l10n.xpCalcDailyXp(dailyXpResult!),
                    style: const TextStyle(
                      color: Color(0xFF9C6FFF),
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Gesamt-XP — Sekundärinfo
                  Text(
                    l10n.xpCalcTotalXp(totalXpResult!),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.55),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Hinweis: Näherungswerte
            Text(
              l10n.xpCalcApprox,
              style: TextStyle(
                color: Colors.white.withOpacity(0.30),
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  _LevelInput — Eingabefeld für Level-Zahlen
// ──────────────────────────────────────────────────────────────

class _LevelInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;

  const _LevelInput({
    required this.controller,
    required this.label,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.55),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.25),
                fontWeight: FontWeight.w400,
                fontSize: 18,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  _PlaytimeXpSection
// ══════════════════════════════════════════════════════════════

class _PlaytimeXpSection extends StatelessWidget {
  final AppLocalizations l10n;

  const _PlaytimeXpSection({required this.l10n});

  @override
  Widget build(BuildContext context) {
    // Sortiert nach XP/Minute absteigend (hilfreichste Modi zuerst)
    final sorted = [..._kPlaytimeModes]..sort((a, b) => b.$2.compareTo(a.$2));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sektions-Header
        Text(
          l10n.xpCalcPlaytime.toUpperCase(),
          style: TextStyle(
            color: Colors.white.withOpacity(0.38),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 10),

        // Tabelle
        OrbitGlassCard(
          child: Column(
            children: [
              // Spalten-Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Modus',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.40),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 90,
                      child: Text(
                        'XP/Min',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.40),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 100,
                      child: Text(
                        l10n.xpCalcWeeklyLimit,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.40),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Trennlinie
              Container(height: 1, color: Colors.white.withOpacity(0.07)),

              // Modus-Zeilen
              ...sorted.asMap().entries.map((entry) {
                final i = entry.key;
                final (name, xpMin, weeklyLimit) = entry.value;
                final isLast = i == sorted.length - 1;
                final hasLimit = weeklyLimit > 0;

                // Farbe nach XP/Minute (höher = grüner)
                final maxXp = sorted.first.$2.toDouble();
                final ratio = xpMin / maxXp;
                final color = Color.lerp(
                  const Color(0xFF9C6FFF),
                  const Color(0xFF00E676),
                  ratio,
                )!;

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 11, 16, 11),
                      child: Row(
                        children: [
                          // Farbpunkt + Modus-Name
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          // XP/Minute
                          SizedBox(
                            width: 90,
                            child: Text(
                              '${_fmtNum(xpMin)} XP',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          // Wöchentliches Limit
                          SizedBox(
                            width: 100,
                            child: Text(
                              hasLimit
                                  ? '${_fmtNum(weeklyLimit ~/ 1000)}k'
                                  : l10n.xpCalcNoLimit,
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                color: hasLimit
                                    ? Colors.white.withOpacity(0.45)
                                    : const Color(0xFF00E676),
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isLast)
                      Container(
                        height: 1,
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        color: Colors.white.withOpacity(0.05),
                      ),
                  ],
                );
              }),
            ],
          ),
        ),

        // Hinweis-Text unter der Tabelle
        const SizedBox(height: 8),
        Text(
          'Alle Modi außer Creative haben ein wöchentliches XP-Limit von 4.000.000 XP.',
          style: TextStyle(
            color: Colors.white.withOpacity(0.30),
            fontSize: 11,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  /// Formatiert eine Zahl mit Punkt als Tausender-Trenner.
  static String _fmtNum(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}
