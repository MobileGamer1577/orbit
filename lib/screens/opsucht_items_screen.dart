import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/opsucht_sync_service.dart';
import '../theme/orbit_theme.dart';
import '../widgets/orbit_glass_card.dart';

// ══════════════════════════════════════════════════════════════
//
//  📦 OPSUCHT ITEMS SCREEN
//  Datei: lib/screens/opsucht_items_screen.dart
//
//  Item-Datenbank — Quellen (Priorität):
//    1. lib/opsucht/items/ im Orbit-Repo (GitHub)
//    2. Fallback: geldbedarf/OPMOD_REPO
//
//  Features:
//    • Suche nach displayname, internalname, material
//    • Grid/List-Toggle
//    • Detail-Sheet bei Tap (inkl. Lore + NBT-Tag kopierbar)
//    • Filter-Struktur vorbereitet für spätere Erweiterung
//
// ══════════════════════════════════════════════════════════════

class OpSuchtItemsScreen extends StatefulWidget {
  const OpSuchtItemsScreen({super.key});

  @override
  State<OpSuchtItemsScreen> createState() => _OpSuchtItemsScreenState();
}

class _OpSuchtItemsScreenState extends State<OpSuchtItemsScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;
  String _query = '';
  bool   _gridView = false;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearch);
    OpSuchtSyncService.instance.addListener(_onUpdate);

    if (!OpSuchtSyncService.instance.itemsLoaded) {
      OpSuchtSyncService.instance.loadItems();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    OpSuchtSyncService.instance.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  void _onSearch() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (mounted) setState(() => _query = _searchCtrl.text.trim());
    });
  }

  // ── Suche über den Service (nutzt searchIndex) ─────────────
  List<OpSuchtItem> _filtered() {
    return OpSuchtSyncService.instance.search(_query);
  }

  void _openDetail(OpSuchtItem item) {
    showModalBottomSheet(
      context:            context,
      isScrollControlled: true,
      backgroundColor:    Colors.transparent,
      builder: (_) => _ItemDetailSheet(item: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service  = OpSuchtSyncService.instance;
    final filtered = _filtered();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: OrbitBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.arrow_back,
                          color: Colors.white.withOpacity(0.90)),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Item Datenbank',
                            style: TextStyle(
                              fontSize:      24,
                              fontWeight:    FontWeight.w900,
                              color:         Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                          Text(
                            'OpSucht.net · OPMOD_REPO',
                            style: TextStyle(
                                color:      Colors.white.withOpacity(0.45),
                                fontSize:   12,
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),

                    // Refresh-Button
                    if (!service.syncing)
                      IconButton(
                        icon: Icon(Icons.refresh,
                            color: Colors.white.withOpacity(0.70)),
                        onPressed: () => service.loadItems(force: true),
                      )
                    else
                      const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Color(0xFF00E676)),
                        ),
                      ),

                    // Grid/List-Toggle
                    IconButton(
                      icon: Icon(
                        _gridView ? Icons.list : Icons.grid_view,
                        color: Colors.white.withOpacity(0.60),
                      ),
                      onPressed: () => setState(() => _gridView = !_gridView),
                    ),
                  ],
                ),
              ),

              // ── Suchfeld ──────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: OrbitGlassCard(
                  child: TextField(
                    controller: _searchCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText:  'Name, Material oder CMD…',
                      hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.40)),
                      prefixIcon: Icon(Icons.search,
                          color: Colors.white.withOpacity(0.55)),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear,
                                  color: Colors.white.withOpacity(0.55)),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _query = '');
                              })
                          : null,
                      border:        InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                ),
              ),

              // ── Ergebnis-Zähler ───────────────────────
              if (service.itemsLoaded)
                Padding(
                  padding: const EdgeInsets.only(left: 20, bottom: 4),
                  child: Text(
                    '${filtered.length} Items',
                    style: TextStyle(
                        color:      Colors.white.withOpacity(0.38),
                        fontSize:   12,
                        fontWeight: FontWeight.w500),
                  ),
                ),

              // ── Inhalt ────────────────────────────────
              Expanded(child: _buildBody(service, filtered)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(OpSuchtSyncService service, List<OpSuchtItem> filtered) {
    // Laden-Zustand (erstmaliges Laden)
    if (!service.itemsLoaded) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Color(0xFF00E676)),
            const SizedBox(height: 16),
            Text(
              'Items werden geladen…',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.55), fontSize: 14),
            ),
            const SizedBox(height: 6),
            Text(
              'Kann beim ersten Start einen Moment dauern.',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.30), fontSize: 12),
            ),
          ],
        ),
      );
    }

    // Fehler-Zustand (und kein Cache)
    if (service.error != null && filtered.isEmpty) {
      return _ErrorWidget(
        error:   service.error!,
        onRetry: () => service.loadItems(force: true),
      );
    }

    // Leer-Zustand
    if (filtered.isEmpty) {
      return Center(
        child: Text(
          _query.isEmpty ? 'Keine Items vorhanden.' : 'Keine Treffer.',
          style: TextStyle(
              color: Colors.white.withOpacity(0.45), fontSize: 15),
        ),
      );
    }

    // Grid-Ansicht
    if (_gridView) {
      return GridView.builder(
        physics:  const BouncingScrollPhysics(),
        padding:  const EdgeInsets.fromLTRB(16, 4, 16, 32),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount:   2,
          mainAxisSpacing:  10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.3,
        ),
        itemCount:   filtered.length,
        itemBuilder: (context, i) => _ItemGridCard(
          item:  filtered[i],
          onTap: () => _openDetail(filtered[i]),
        ),
      );
    }

    // Listen-Ansicht (Standard)
    return ListView.separated(
      physics:          const BouncingScrollPhysics(),
      padding:          const EdgeInsets.fromLTRB(16, 4, 16, 32),
      itemCount:        filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder:      (context, i) => _ItemListTile(
        item:  filtered[i],
        onTap: () => _openDetail(filtered[i]),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  Item List Tile
// ──────────────────────────────────────────────────────────────

class _ItemListTile extends StatelessWidget {
  final OpSuchtItem item;
  final VoidCallback onTap;

  const _ItemListTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final name = item.displayname.isNotEmpty
        ? item.displayname
        : item.internalname;

    return OrbitGlassCard(
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          child: Row(
            children: [
              // Icon
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color:        const Color(0xFF00E676).withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                  border:       Border.all(
                      color: const Color(0xFF00E676).withOpacity(0.25)),
                ),
                child: Icon(Icons.inventory_2_outlined,
                    color: const Color(0xFF00E676).withOpacity(0.70),
                    size: 20),
              ),
              const SizedBox(width: 12),

              // Name + Material + Badges
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                          color:      Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize:   14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.material.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.material,
                        style: TextStyle(
                            color:      Colors.white.withOpacity(0.45),
                            fontSize:   12,
                            fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (item.cmd > 0) ...[
                      const SizedBox(height: 4),
                      Row(children: [
                        _Badge(label: 'CMD ${item.cmd}',
                            color: const Color(0xFF9C6FFF)),
                        if (item.shardPrice.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          _Badge(
                              label: '💎 ${item.shardPrice}',
                              color: const Color(0xFF00D4FF)),
                        ],
                      ]),
                    ],
                  ],
                ),
              ),

              Icon(Icons.chevron_right,
                  color: Colors.white.withOpacity(0.30), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  Item Grid Card
// ──────────────────────────────────────────────────────────────

class _ItemGridCard extends StatelessWidget {
  final OpSuchtItem item;
  final VoidCallback onTap;

  const _ItemGridCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final name = item.displayname.isNotEmpty
        ? item.displayname
        : item.internalname;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end:   Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.09),
              Colors.white.withOpacity(0.03),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: const Color(0xFF00E676).withOpacity(0.25), width: 1.1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.inventory_2_outlined,
                color: const Color(0xFF00E676).withOpacity(0.60), size: 24),
            const Spacer(),
            Text(
              name,
              style: const TextStyle(
                  color:      Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize:   13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (item.material.isNotEmpty)
              Text(
                item.material,
                style: TextStyle(
                    color:    Colors.white.withOpacity(0.40),
                    fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  Item Detail Sheet
//
//  Zeigt alle verfügbaren Felder.
//  lore wird als mehrzeiliger Text dargestellt.
//  nbttag ist selektierbar + kopierbar.
// ──────────────────────────────────────────────────────────────

class _ItemDetailSheet extends StatelessWidget {
  final OpSuchtItem item;
  const _ItemDetailSheet({required this.item});

  void _copy(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label kopiert ✓'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final name   = item.displayname.isNotEmpty
        ? item.displayname
        : item.internalname;

    return Padding(
      padding: EdgeInsets.only(left: 12, right: 12, bottom: 12 + bottom),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Material(
          color: const Color(0xFF1A1026).withOpacity(0.97),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              mainAxisSize:        MainAxisSize.min,
              crossAxisAlignment:  CrossAxisAlignment.start,
              children: [

                // ── Titel ─────────────────────────────
                Row(
                  children: [
                    Icon(Icons.inventory_2_outlined,
                        color: const Color(0xFF00E676).withOpacity(0.80),
                        size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          color:      Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize:   18,
                          height:     1.2,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),
                _Divider(),
                const SizedBox(height: 12),

                // ── Details ───────────────────────────
                if (item.material.isNotEmpty)
                  _InfoRow('Material', item.material),
                if (item.cmd > 0)
                  _InfoRow('CMD', '${item.cmd}'),
                if (item.damage > 0)
                  _InfoRow('Damage', '${item.damage}'),
                if (item.shardPrice.isNotEmpty)
                  _InfoRow('Shard-Preis', item.shardPrice),
                if (item.alternativeRaritys.isNotEmpty)
                  _InfoRow('Seltenheiten', item.alternativeRaritys),
                if (item.capturedAt.isNotEmpty)
                  _InfoRow('Erfasst am', _fmtDate(item.capturedAt)),
                if (item.internalname.isNotEmpty)
                  _InfoRow('Internal Name', item.internalname),

                // ── Lore (Array → mehrzeiliger Text) ──
                if (item.lore.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _Divider(),
                  const SizedBox(height: 12),
                  _SectionLabel('LORE'),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:        Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(12),
                      border:       Border.all(
                          color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Text(
                      item.lore,
                      style: TextStyle(
                        color:      Colors.white.withOpacity(0.70),
                        fontSize:   13,
                        height:     1.6,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],

                // ── NBT-Tag (selektierbar + kopierbar) ─
                if (item.nbttag.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _Divider(),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _SectionLabel('NBT-TAG'),
                      GestureDetector(
                        onTap: () => _copy(context, item.nbttag, 'NBT-Tag'),
                        child: Row(children: [
                          Icon(Icons.copy,
                              size:  14,
                              color: Colors.white.withOpacity(0.45)),
                          const SizedBox(width: 4),
                          Text('Kopieren',
                              style: TextStyle(
                                  color:      Colors.white.withOpacity(0.45),
                                  fontSize:   12,
                                  fontWeight: FontWeight.w600)),
                        ]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:        Colors.black.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(12),
                      border:       Border.all(
                          color: Colors.white.withOpacity(0.08)),
                    ),
                    child: SelectableText(
                      item.nbttag,
                      style: const TextStyle(
                        color:      Color(0xFF9C6FFF),
                        fontSize:   11,
                        fontFamily: 'monospace',
                        height:     1.5,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// ISO-8601 → lesbares Datum
  String _fmtDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
    } catch (_) {
      return iso;
    }
  }
}

// ──────────────────────────────────────────────────────────────
//  Kleine Hilfs-Widgets
// ──────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String label;
  final Color  color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      color:        color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(5),
      border:       Border.all(color: color.withOpacity(0.35)),
    ),
    child: Text(label,
        style: TextStyle(
            color: color, fontSize: 10, fontWeight: FontWeight.w700)),
  );
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      color:         Colors.white.withOpacity(0.40),
      fontSize:      11,
      fontWeight:    FontWeight.w700,
      letterSpacing: 1.2,
    ),
  );
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(label,
              style: TextStyle(
                  color:      Colors.white.withOpacity(0.45),
                  fontWeight: FontWeight.w600,
                  fontSize:   13)),
        ),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  color:      Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize:   13)),
        ),
      ],
    ),
  );
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(height: 1, color: Colors.white.withOpacity(0.08));
}

class _ErrorWidget extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorWidget({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded, color: Colors.white24, size: 48),
          const SizedBox(height: 16),
          const Text(
            'Items konnten nicht geladen werden.',
            style: TextStyle(
                color:      Colors.white,
                fontSize:   16,
                fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(error,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.35), fontSize: 11),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onRetry,
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF00E676).withOpacity(0.80)),
            icon:  const Icon(Icons.refresh),
            label: const Text('Erneut versuchen'),
          ),
        ],
      ),
    ),
  );
}
