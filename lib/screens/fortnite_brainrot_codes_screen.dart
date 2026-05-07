import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../storage/task_store.dart';
import '../theme/orbit_theme.dart';
import '../widgets/orbit_glass_card.dart';

// ══════════════════════════════════════════════════════════════
//
//  🔑 BRAINROT CODES SCREEN
//  Datei: lib/screens/fortnite_brainrot_codes_screen.dart
//
//  Zeigt die Codes für „Steal the Brainrot" an:
//    • Insel-Code oben (tipp-zum-Kopieren)
//    • Liste abhakbarer Secret-Codes darunter
//
//  Fortschritt wird lokal in Hive gespeichert (TaskStore).
//  Schlüssel-Format: 'brainrot:{code_id}'
//
//  ✏️  CODES AKTUALISIEREN (kein Code-Änderung nötig):
//    → _kIslandCode: Insel-Code eintragen
//    → _kCodes: Codes hinzufügen / entfernen / anpassen
//
// ══════════════════════════════════════════════════════════════

// ── Insel-Code ─────────────────────────────────────────────────
//
// ✏️  HIER den echten Island-Code eintragen sobald verfügbar:
//     Format: 'XXXX-XXXX-XXXX'
//
const String _kIslandCode = 'XXXX-XXXX-XXXX'; // Placeholder

// ── Titel der Seite ────────────────────────────────────────────
//
// ✏️  HIER den Titel anpassen (z.B. Monat aktualisieren):
//
const String _kPageTitle = 'Steal the Brainrot Codes April 2026';

// ── Secret-Codes Liste ─────────────────────────────────────────
//
// ✏️  HIER Codes hinzufügen / anpassen:
// Format: _BrainrotCode(id: 'eindeutige_id', code: 'CODE', description: 'Was dieser Code macht')
// WICHTIG: id darf sich NICHT ändern (sonst verlieren Nutzer ihren Fortschritt)
//
const List<_BrainrotCode> _kCodes = [
  _BrainrotCode(
    id: 'stb_001',
    code: '1234',
    description: 'Starter Egg',
  ),
  _BrainrotCode(
    id: 'stb_002',
    code: '5678',
    description: 'Random Brainrot',
  ),
  _BrainrotCode(
    id: 'stb_003',
    code: '9012',
    description: 'Sigma Egg',
  ),
  _BrainrotCode(
    id: 'stb_004',
    code: '3456',
    description: 'Rare Brainrot',
  ),
  _BrainrotCode(
    id: 'stb_005',
    code: '7890',
    description: 'Mystery Box',
  ),
  _BrainrotCode(
    id: 'stb_006',
    code: '112233',
    description: 'Jurassic Brainrot Egg',
  ),
  _BrainrotCode(
    id: 'stb_007',
    code: '445566',
    description: 'Fusion Skip',
  ),
  _BrainrotCode(
    id: 'stb_008',
    code: '778899',
    description: 'Epic Brainrot',
  ),
  // ← NEUEN CODE HIER EINFÜGEN:
  // _BrainrotCode(
  //   id: 'stb_009',        // Eindeutige ID (nie ändern!)
  //   code: 'DEIN_CODE',    // Der einzugebende Code
  //   description: 'Was dieser Code bringt',
  // ),
];

// ──────────────────────────────────────────────────────────────
//  Datenmodell
// ──────────────────────────────────────────────────────────────

class _BrainrotCode {
  final String id;
  final String code;
  final String description;

  const _BrainrotCode({
    required this.id,
    required this.code,
    required this.description,
  });

  /// Hive-Schlüssel für den Abhak-Zustand
  String get taskKey => 'brainrot:$id';
}

// ══════════════════════════════════════════════════════════════
//  SCREEN
// ══════════════════════════════════════════════════════════════

class FortniteBrainrotCodesScreen extends StatefulWidget {
  const FortniteBrainrotCodesScreen({super.key});

  @override
  State<FortniteBrainrotCodesScreen> createState() =>
      _FortniteBrainrotCodesScreenState();
}

class _FortniteBrainrotCodesScreenState
    extends State<FortniteBrainrotCodesScreen> {

  // ── Insel-Code kopieren ───────────────────────────────────

  void _copyIslandCode() {
    Clipboard.setData(ClipboardData(text: _kIslandCode));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$_kIslandCode  ✓'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Secret-Code abhaken ───────────────────────────────────

  Future<void> _toggle(_BrainrotCode code) async {
    await TaskStore.setDone(code.taskKey, !TaskStore.isDone(code.taskKey));
    if (mounted) setState(() {});
  }

  // ── Fortschritt berechnen ─────────────────────────────────

  int get _doneCount =>
      _kCodes.where((c) => TaskStore.isDone(c.taskKey)).length;

  @override
  Widget build(BuildContext context) {
    final done = _doneCount;
    final total = _kCodes.length;
    final progress = total == 0 ? 0.0 : done / total;

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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _kPageTitle,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.3,
                              height: 1.2,
                            ),
                          ),
                          Text(
                            '$done / $total Codes eingelöst',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.50),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Fortschrittsbalken ───────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 5,
                    backgroundColor: Colors.white.withOpacity(0.10),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFFFF8C00)),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                  children: [
                    // ── 1. Insel-Code (kopierbar) ────────────
                    _SectionLabel('INSEL CODE'),
                    const SizedBox(height: 8),
                    _IslandCodeCard(
                      code: _kIslandCode,
                      onTap: _copyIslandCode,
                    ),

                    const SizedBox(height: 20),

                    // ── 2. Secret Codes (abhakbar) ────────────
                    _SectionLabel('SECRET CODES'),
                    const SizedBox(height: 8),

                    // Trennungshinweis
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        'Tippe auf einen Code um ihn als eingelöst zu markieren.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.35),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    // Codes-Liste
                    ..._kCodes.asMap().entries.map((entry) {
                      final i = entry.key;
                      final code = entry.value;
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: i < _kCodes.length - 1 ? 8 : 0,
                        ),
                        child: _CodeTile(
                          code: code,
                          isDone: TaskStore.isDone(code.taskKey),
                          onToggle: () => _toggle(code),
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
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  _IslandCodeCard — Großer kopierbarer Insel-Code oben
// ──────────────────────────────────────────────────────────────

class _IslandCodeCard extends StatelessWidget {
  final String code;
  final VoidCallback onTap;

  const _IslandCodeCard({required this.code, required this.onTap});

  bool get _isPlaceholder => code.contains('X');

  @override
  Widget build(BuildContext context) {
    return OrbitGlassCard(
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: _isPlaceholder ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Insel-Code groß anzeigen
              Row(
                children: [
                  Icon(
                    Icons.tag,
                    size: 22,
                    color: _isPlaceholder
                        ? Colors.white.withOpacity(0.30)
                        : const Color(0xFFFF8C00),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      code,
                      style: TextStyle(
                        color: _isPlaceholder
                            ? Colors.white.withOpacity(0.40)
                            : const Color(0xFFFF8C00),
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  if (!_isPlaceholder)
                    Icon(
                      Icons.copy_rounded,
                      size: 20,
                      color: const Color(0xFFFF8C00).withOpacity(0.70),
                    ),
                ],
              ),

              const SizedBox(height: 10),

              // Hinweistext
              Text(
                _isPlaceholder
                    ? 'Insel-Code wird noch bekannt gegeben.'
                    : 'Tippe um den Code zu kopieren.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.40),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  _CodeTile — Abhakbarer Secret Code
// ──────────────────────────────────────────────────────────────

class _CodeTile extends StatelessWidget {
  final _BrainrotCode code;
  final bool isDone;
  final VoidCallback onToggle;

  const _CodeTile({
    required this.code,
    required this.isDone,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFFF8C00);

    return OrbitGlassCard(
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(
            children: [
              // Checkbox
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: isDone
                      ? accent.withOpacity(0.80)
                      : Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDone ? accent : Colors.white.withOpacity(0.22),
                    width: 1.5,
                  ),
                ),
                child: isDone
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 14),

              // Code + Beschreibung
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      code.code,
                      style: TextStyle(
                        color: isDone
                            ? Colors.white.withOpacity(0.45)
                            : Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        letterSpacing: 0.5,
                        decoration: isDone ? TextDecoration.lineThrough : null,
                        decorationColor: Colors.white.withOpacity(0.35),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      code.description,
                      style: TextStyle(
                        color: Colors.white.withOpacity(isDone ? 0.30 : 0.55),
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
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

// ──────────────────────────────────────────────────────────────
//  _SectionLabel — Sektions-Überschrift
// ──────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      color: Colors.white.withOpacity(0.38),
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.4,
    ),
  );
}
