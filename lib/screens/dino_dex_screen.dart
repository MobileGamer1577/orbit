import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../storage/task_store.dart';
import '../theme/orbit_theme.dart';
import '../widgets/orbit_glass_card.dart';

// ══════════════════════════════════════════════════════════════
//
//  🦕 DINO DEX
//  Datei: lib/screens/dino_dex_screen.dart
//
//  Zwei Screens in einer Datei:
//    DinoDexScreen  → Kategorie-Übersicht
//    DinoListScreen → Dino-Liste einer Kategorie
//
//  Daten kommen aus zwei JSON-Dateien:
//    assets/data/dino_dex.json       → Kategorien + Dino-IDs
//    assets/data/dinos_database.json → Dino-Details (Name, Seltenheit)
//
//  Fortschritt (Häkchen) wird in Hive gespeichert —
//  genau wie beim Quest-System, über TaskStore.
//
//  ✏️  NEUEN DINO HINZUFÜGEN:
//    1. ID + Daten in dinos_database.json eintragen
//    2. ID in der richtigen Kategorie in dino_dex.json eintragen
//    → Kein Code ändern nötig!
//
//  ✏️  NEUE KATEGORIE HINZUFÜGEN:
//    1. Neuen Kategorie-Block in dino_dex.json eintragen
//    → Kein Code ändern nötig!
//
// ══════════════════════════════════════════════════════════════

// ──────────────────────────────────────────────────────────────
//
//  🎨 SELTENHEITS-SYSTEM — zentral definiert
//
//  Alles über Seltenheiten steht hier an einer Stelle.
//  Farben, Sortier-Reihenfolge und Anzeige-Namen.
//  Nirgendwo sonst hardcoden!
//
// ──────────────────────────────────────────────────────────────

/// Sortier-Reihenfolge der Seltenheiten (Index 0 = niedrigste)
const _rarityOrder = [
  'common',
  'rare',
  'epic',
  'legendary',
  'mythic',
  'jurassic',
];

/// Farben pro Seltenheit
const _rarityColors = {
  'common': Color(0xFF2ECC40), // Grün
  'rare': Color(0xFF0077FF), // Blau
  'epic': Color(0xFF9B59B6), // Lila
  'legendary': Color(0xFFFFD700), // Gold
  'mythic': Color(0xFFFF1744), // Rot
  'jurassic': Color(0xFFCCCCCC), // Grau (Basis — Badge ist animiert)
};

/// Anzeige-Namen pro Seltenheit
const _rarityLabels = {
  'common': 'Common',
  'rare': 'Rare',
  'epic': 'Epic',
  'legendary': 'Legendary',
  'mythic': 'Mythic',
  'jurassic': 'Jurassic',
};

/// Gibt die Farbe einer Seltenheit zurück.
/// Unbekannte Seltenheiten → Grau als Fallback.
Color _rarityColor(String rarity) =>
    _rarityColors[rarity.toLowerCase()] ?? const Color(0xFF8F8F8F);

/// Gibt den Anzeige-Namen einer Seltenheit zurück.
String _rarityLabel(String rarity) =>
    _rarityLabels[rarity.toLowerCase()] ?? rarity;

/// Gibt den Sortier-Index einer Seltenheit zurück.
/// Unbekannte Seltenheiten → am Ende der Liste.
int _rarityIndex(String rarity) {
  final i = _rarityOrder.indexOf(rarity.toLowerCase());
  return i == -1 ? 999 : i;
}

// ──────────────────────────────────────────────────────────────
//  Interne Datenmodelle
// ──────────────────────────────────────────────────────────────

class _DinoCategory {
  final String id;
  final String label;
  final String icon;
  final List<String> dinoIds;

  const _DinoCategory({
    required this.id,
    required this.label,
    required this.icon,
    required this.dinoIds,
  });

  factory _DinoCategory.fromJson(Map<String, dynamic> j, String lang) {
    final labelMap = j['label'];
    final String label = labelMap is Map
        ? ((labelMap[lang] ?? labelMap['de'] ?? '') as String)
        : j['id'] as String;

    return _DinoCategory(
      id: (j['id'] as String?) ?? '',
      label: label,
      icon: (j['icon'] as String?) ?? '🦕',
      dinoIds: (j['dinos'] as List?)?.cast<String>() ?? [],
    );
  }
}

class _DinoEntry {
  final String id;
  final String name;
  final String rarity;

  const _DinoEntry({
    required this.id,
    required this.name,
    required this.rarity,
  });
}

// ══════════════════════════════════════════════════════════════
//  SCREEN 1: DinoDexScreen — Kategorie-Übersicht
// ══════════════════════════════════════════════════════════════

class DinoDexScreen extends StatefulWidget {
  const DinoDexScreen({super.key});

  @override
  State<DinoDexScreen> createState() => _DinoDexScreenState();
}

class _DinoDexScreenState extends State<DinoDexScreen> {
  List<_DinoCategory> _categories = [];
  Map<String, dynamic> _dinoDb = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final lang = 'de';

      final results = await Future.wait([
        rootBundle.loadString('assets/data/dino_dex.json'),
        rootBundle.loadString('assets/data/dinos_database.json'),
      ]);

      final dexJson = jsonDecode(results[0]) as Map<String, dynamic>;
      _dinoDb = jsonDecode(results[1]) as Map<String, dynamic>;

      final rawCats = dexJson['categories'] as List? ?? [];
      _categories = rawCats
          .whereType<Map<String, dynamic>>()
          .map((c) => _DinoCategory.fromJson(c, lang))
          .toList();
    } catch (e) {
      _categories = [];
    }

    if (mounted) setState(() => _loading = false);
  }

  int _ownedCount(_DinoCategory cat) =>
      cat.dinoIds.where((id) => TaskStore.isDone('dino:$id')).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: OrbitBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '🦕 Dino Dex',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                          Text(
                            'Steal the Dino',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white54,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF9C6FFF),
                        ),
                      )
                    : _categories.isEmpty
                    ? Center(
                        child: Text(
                          'Keine Kategorien gefunden.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.45),
                          ),
                        ),
                      )
                    : ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                        itemCount: _categories.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, i) {
                          final cat = _categories[i];
                          final owned = _ownedCount(cat);
                          final total = cat.dinoIds.length;
                          final progress = total == 0 ? 0.0 : owned / total;

                          return _CategoryCard(
                            category: cat,
                            owned: owned,
                            total: total,
                            progress: progress,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DinoListScreen(
                                  category: cat,
                                  dinoDb: _dinoDb,
                                ),
                              ),
                            ).then((_) => setState(() {})),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final _DinoCategory category;
  final int owned;
  final int total;
  final double progress;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
    required this.owned,
    required this.total,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OrbitGlassCard(
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(category.icon, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          '$owned / $total Dinos',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.50),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: Colors.white.withOpacity(0.35),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: Colors.white.withOpacity(0.10),
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF9C6FFF)),
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
//  SCREEN 2: DinoListScreen — Dino-Liste einer Kategorie
// ══════════════════════════════════════════════════════════════

class DinoListScreen extends StatefulWidget {
  final _DinoCategory category;
  final Map<String, dynamic> dinoDb;

  const DinoListScreen({
    super.key,
    required this.category,
    required this.dinoDb,
  });

  @override
  State<DinoListScreen> createState() => _DinoListScreenState();
}

class _DinoListScreenState extends State<DinoListScreen> {
  /// Sortierung — GLOBAL:
  ///
  ///   Gruppe 1: Alle NICHT abgehakten Dinos
  ///             → sortiert nach Seltenheit (common → jurassic)
  ///
  ///   Gruppe 2: Alle abgehakten Dinos
  ///             → sortiert nach Seltenheit (common → jurassic)
  ///
  ///   Damit wandert jeder abgehakte Dino ans Ende,
  ///   unabhängig davon wie selten er ist.
  List<_DinoEntry> _buildSortedList() {
    final entries = widget.category.dinoIds.map((id) {
      final data = widget.dinoDb[id] as Map<String, dynamic>?;
      return _DinoEntry(
        id: id,
        name: (data?['name'] as String?) ?? id,
        rarity: (data?['rarity'] as String?) ?? 'common',
      );
    }).toList();

    entries.sort((a, b) {
      final aDone = TaskStore.isDone('dino:${a.id}') ? 1 : 0;
      final bDone = TaskStore.isDone('dino:${b.id}') ? 1 : 0;

      // 1. GLOBAL: unchecked (0) vor checked (1)
      if (aDone != bDone) return aDone.compareTo(bDone);

      // 2. Innerhalb der Gruppe: Seltenheit (common → jurassic)
      final ri = _rarityIndex(a.rarity).compareTo(_rarityIndex(b.rarity));
      if (ri != 0) return ri;

      // 3. Alphabetisch als Tiebreaker
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return entries;
  }

  Future<void> _toggle(String dinoId) async {
    final key = 'dino:$dinoId';
    await TaskStore.setDone(key, !TaskStore.isDone(key));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final dinos = _buildSortedList();
    final owned = dinos.where((d) => TaskStore.isDone('dino:${d.id}')).length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: OrbitBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                            '${widget.category.icon}  ${widget.category.label}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                          Text(
                            '$owned / ${dinos.length} gesammelt',
                            style: TextStyle(
                              fontSize: 13,
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

              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: dinos.isEmpty ? 0 : owned / dinos.length,
                    minHeight: 6,
                    backgroundColor: Colors.white.withOpacity(0.10),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF9C6FFF)),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              Expanded(
                child: dinos.isEmpty
                    ? Center(
                        child: Text(
                          'Keine Dinos in dieser Kategorie.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.45),
                          ),
                        ),
                      )
                    : ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                        itemCount: dinos.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final dino = dinos[i];
                          final isDone = TaskStore.isDone('dino:${dino.id}');
                          return _DinoTile(
                            dino: dino,
                            isDone: isDone,
                            onToggle: () => _toggle(dino.id),
                          );
                        },
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
//
//  🦖 _DinoTile — Ein einzelner Dino-Eintrag
//
// ──────────────────────────────────────────────────────────────

class _DinoTile extends StatefulWidget {
  final _DinoEntry dino;
  final bool isDone;
  final VoidCallback onToggle;

  const _DinoTile({
    required this.dino,
    required this.isDone,
    required this.onToggle,
  });

  @override
  State<_DinoTile> createState() => _DinoTileState();
}

class _DinoTileState extends State<_DinoTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final color = _rarityColor(widget.dino.rarity);
    final isJurassic = widget.dino.rarity.toLowerCase() == 'jurassic';

    // ── Dino-Name: Shimmer für Jurassic (nicht abgehakt), sonst normal ──
    final Widget nameWidget = (isJurassic && !widget.isDone)
        ? _JurassicShimmer(
            child: Text(
              widget.dino.name,
              style: const TextStyle(
                // ShaderMask überschreibt diese Farbe mit dem Shimmer-Gradient
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          )
        : Text(
            widget.dino.name,
            style: TextStyle(
              color: widget.isDone
                  ? Colors.white.withOpacity(0.45)
                  : Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 15,
              decoration: widget.isDone
                  ? TextDecoration.lineThrough
                  : TextDecoration.none,
              decorationColor: Colors.white.withOpacity(0.35),
            ),
          );

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onToggle();
      },
      onTapCancel: () => setState(() => _pressed = false),

      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOut,

        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: widget.isDone
                ? color.withOpacity(0.15)
                : color.withOpacity(0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.isDone
                  ? color.withOpacity(0.55)
                  : color.withOpacity(isJurassic ? 0.35 : 0.20),
              width: isJurassic ? 1.5 : 1.2,
            ),
          ),
          child: Row(
            children: [
              // ── Seltenheits-Farbstreifen ────────────────
              Container(
                width: 4,
                height: 44,
                decoration: BoxDecoration(
                  // Jurassic: statischer grau→weiß Verlauf (kein Shimmer nötig)
                  gradient: isJurassic
                      ? const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFFFFFFFF), Color(0xFF888888)],
                        )
                      : null,
                  color: isJurassic ? null : color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 14),

              // ── Name + Badge ─────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    nameWidget,
                    const SizedBox(height: 5),
                    isJurassic
                        ? const _JurassicBadge()
                        : _StaticBadge(rarity: widget.dino.rarity),
                  ],
                ),
              ),

              // ── Checkbox ────────────────────────────────
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: widget.isDone
                      ? color.withOpacity(0.80)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: widget.isDone
                        ? color
                        : Colors.white.withOpacity(0.25),
                    width: 1.5,
                  ),
                ),
                child: widget.isDone
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  🏷  _StaticBadge — Farbiger Badge für alle außer Jurassic
// ──────────────────────────────────────────────────────────────

class _StaticBadge extends StatelessWidget {
  final String rarity;
  const _StaticBadge({required this.rarity});

  @override
  Widget build(BuildContext context) {
    final color = _rarityColor(rarity);
    final label = _rarityLabel(rarity);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.45)),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
//
//  ✨ _JurassicShimmer — Wiederverwendbarer Shimmer-Wrapper
//
//  Lässt einen Lichtstreifen von links nach rechts laufen.
//  Verwendet ShaderMask mit einem animierten LinearGradient.
//
//  Funktioniert so:
//    • AnimationController läuft 0.0 → 1.0 in einer Loop
//      (KEIN reverse — nur links → rechts, dann Neustart)
//    • Der Gradient-Ursprung (begin/end) verschiebt sich mit:
//        begin = Alignment(-3 + 6t, 0)
//        end   = Alignment(-2 + 6t, 0)
//      → t=0:   Gradient komplett links  → Widget zeigt Grau
//      → t≈0.5: Highlight mittig sichtbar → weiß
//      → t=1:   Gradient komplett rechts → Widget zeigt Grau
//    • tileMode: clamp → außerhalb → nächste Farbe (grau)
//    • blendMode: srcIn → ShaderMask nur auf Child-Pixel
//    • RepaintBoundary: nur dieses Widget neu zeichnen
//
// ──────────────────────────────────────────────────────────────

class _JurassicShimmer extends StatefulWidget {
  final Widget child;
  const _JurassicShimmer({required this.child});

  @override
  State<_JurassicShimmer> createState() => _JurassicShimmerState();
}

class _JurassicShimmerState extends State<_JurassicShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(); // ← NUR vorwärts — links → rechts, dann Neustart
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) {
          final t = _ctrl.value;
          // Gradient-Fenster wandert von links (-3→-2) nach rechts (3→4).
          // Alignment(-1,0) = linke Kante des Widgets
          // Alignment( 1,0) = rechte Kante des Widgets
          final begin = Alignment(-3.0 + 6.0 * t, 0);
          final end = Alignment(-2.0 + 6.0 * t, 0);

          return ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              begin: begin,
              end: end,
              colors: const [
                Color(0xFF777777), // grau — links (Ruhezustand)
                Color(0xFFFFFFFF), // weiß — Mitte (Highlight)
                Color(0xFF777777), // grau — rechts (Ruhezustand)
              ],
              tileMode: TileMode.clamp,
            ).createShader(bounds),
            blendMode: BlendMode.srcIn,
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  🏷  _JurassicBadge — Shimmer-Badge für Jurassic-Seltenheit
//
//  Verwendet _JurassicShimmer, damit Shimmer-Logik nur
//  an einer Stelle definiert ist.
// ──────────────────────────────────────────────────────────────

class _JurassicBadge extends StatelessWidget {
  const _JurassicBadge();

  @override
  Widget build(BuildContext context) {
    return _JurassicShimmer(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          // Hintergrund + Border sind weiß — ShaderMask färbt sie grau/weiß
          color: Colors.white.withOpacity(0.10),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.white, width: 1),
        ),
        child: const Text(
          'JURASSIC',
          style: TextStyle(
            // ShaderMask überschreibt diese Farbe mit dem Shimmer-Gradient
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}
