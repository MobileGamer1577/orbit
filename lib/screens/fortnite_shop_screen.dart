import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/shop_service.dart';
import '../theme/orbit_theme.dart';

// ══════════════════════════════════════════════════════════════
// FILTER
// ══════════════════════════════════════════════════════════════

enum _Filter {
  all,
  // Battle Royale
  outfit, emote, pickaxe, backbling, glider, sidekick, shoe, wrap, bundle,
  // Rocket Racing
  car, decal, wheel, trail, boost,
  // Festival
  jamTrack, instrument,
  // LEGO
  build, decor,
}

const Map<_Filter, String> _filterLabel = {
  _Filter.all:       'Alle',
  _Filter.outfit:    'Outfits',
  _Filter.emote:     'Emotes',
  _Filter.pickaxe:   'Pickaxes',
  _Filter.backbling: 'Backblings',
  _Filter.glider:    'Gliders',
  _Filter.sidekick:  'Sidekicks',
  _Filter.shoe:      'Kicks',
  _Filter.wrap:      'Wraps',
  _Filter.bundle:    'Bundles',
  _Filter.car:       'Cars',
  _Filter.decal:     'Decals',
  _Filter.wheel:     'Wheels',
  _Filter.trail:     'Trails',
  _Filter.boost:     'Boosts',
  _Filter.jamTrack:  'Jam Tracks',
  _Filter.instrument:'Instruments',
  _Filter.build:     'Builds',
  _Filter.decor:     'Decors',
};

// Gruppen: (Gruppenname, Filter-Liste)
const _filterGroups = [
  ('', [_Filter.all]),
  ('BR', [
    _Filter.outfit, _Filter.emote, _Filter.pickaxe,
    _Filter.backbling, _Filter.glider, _Filter.sidekick,
    _Filter.shoe, _Filter.wrap, _Filter.bundle,
  ]),
  ('RR', [_Filter.car, _Filter.decal, _Filter.wheel, _Filter.trail, _Filter.boost]),
  ('Festival', [_Filter.jamTrack, _Filter.instrument]),
  ('LEGO', [_Filter.build, _Filter.decor]),
];

bool _matchesFilter(ShopEntry e, _Filter f) {
  switch (f) {
    case _Filter.all:       return true;
    case _Filter.outfit:    return e.typeValue == 'outfit';
    case _Filter.emote:     return e.typeValue == 'emote';
    case _Filter.pickaxe:   return e.typeValue == 'pickaxe';
    case _Filter.backbling: return e.typeValue == 'backpack';
    case _Filter.glider:    return e.typeValue == 'glider';
    case _Filter.sidekick:  return e.typeValue == 'pet' || e.typeValue == 'sidekick';
    case _Filter.shoe:      return e.typeValue == 'shoe';
    case _Filter.wrap:      return e.typeValue == 'wrap';
    case _Filter.bundle:    return e.isBundle;
    // Rocket Racing — type.value can vary; section name is the safer fallback
    case _Filter.car:
      return e.typeValue.contains('vehicle_body') ||
          e.typeValue == 'car' ||
          (e.sectionName.toLowerCase().contains('racing') && e.typeValue.isEmpty);
    case _Filter.decal:
      return e.typeValue.contains('vehicle_decal') || e.typeValue == 'decal';
    case _Filter.wheel:
      return e.typeValue.contains('vehicle_wheel') || e.typeValue == 'wheel';
    case _Filter.trail:
      return e.typeValue.contains('vehicle_trail') || e.typeValue == 'trail';
    case _Filter.boost:
      return e.typeValue.contains('vehicle_boost') || e.typeValue == 'boost';
    // Festival
    case _Filter.jamTrack:
      return e.hasTracks;
    case _Filter.instrument:
      return e.typeValue == 'instrument' ||
          e.typeValue.contains('guitar') ||
          e.typeValue.contains('bass') ||
          e.typeValue.contains('drum') ||
          e.typeValue.contains('mic');
    // LEGO
    case _Filter.build:
      return e.typeValue.contains('lego_build') ||
          e.typeValue == 'build' ||
          (e.sectionName.toLowerCase().contains('lego') &&
              !e.typeValue.contains('decor'));
    case _Filter.decor:
      return e.typeValue.contains('lego_decor') ||
          e.typeValue == 'decor' ||
          (e.sectionName.toLowerCase().contains('lego') &&
              e.typeValue.contains('decor'));
  }
}

// ══════════════════════════════════════════════════════════════
// SORT
// ══════════════════════════════════════════════════════════════

enum _Sort {
  shopOrder, newestFirst, oldestFirst, series, rarity,
  priceLow, priceHigh, nameAZ, nameZA,
}

const Map<_Sort, String> _sortLabel = {
  _Sort.shopOrder:   'Shop Order',
  _Sort.newestFirst: 'Newest First',
  _Sort.oldestFirst: 'Oldest First',
  _Sort.series:      'Series',
  _Sort.rarity:      'Rarity',
  _Sort.priceLow:    'Price: Low to High',
  _Sort.priceHigh:   'Price: High to Low',
  _Sort.nameAZ:      'Name: A–Z',
  _Sort.nameZA:      'Name: Z–A',
};

const Map<String, int> _rarityOrder = {
  'common': 0, 'uncommon': 1, 'rare': 2, 'epic': 3, 'legendary': 4,
  'mythic': 5, 'exotic': 6, 'transcendent': 7, 'icon': 8,
  'gaminglegends': 9, 'marvel': 10, 'dc': 11, 'starwars': 12, 'slurp': 13,
};

void _sortList(List<ShopEntry> list, _Sort sort) {
  switch (sort) {
    case _Sort.shopOrder:
      list.sort((a, b) => b.sortPriority.compareTo(a.sortPriority));
    case _Sort.newestFirst:
      list.sort((a, b) {
        if (a.inDate == null && b.inDate == null) return 0;
        if (a.inDate == null) return 1;
        if (b.inDate == null) return -1;
        return b.inDate!.compareTo(a.inDate!);
      });
    case _Sort.oldestFirst:
      list.sort((a, b) {
        if (a.inDate == null && b.inDate == null) return 0;
        if (a.inDate == null) return 1;
        if (b.inDate == null) return -1;
        return a.inDate!.compareTo(b.inDate!);
      });
    case _Sort.series:
      list.sort((a, b) => a.seriesValue.compareTo(b.seriesValue));
    case _Sort.rarity:
      list.sort((a, b) {
        final ra = _rarityOrder[a.rarityValue] ?? 0;
        final rb = _rarityOrder[b.rarityValue] ?? 0;
        return rb.compareTo(ra);
      });
    case _Sort.priceLow:
      list.sort((a, b) => a.finalPrice.compareTo(b.finalPrice));
    case _Sort.priceHigh:
      list.sort((a, b) => b.finalPrice.compareTo(a.finalPrice));
    case _Sort.nameAZ:
      list.sort((a, b) =>
          a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));
    case _Sort.nameZA:
      list.sort((a, b) =>
          b.displayName.toLowerCase().compareTo(a.displayName.toLowerCase()));
  }
}

// ══════════════════════════════════════════════════════════════
// RARITY FARBEN
// ══════════════════════════════════════════════════════════════

const Map<String, Color> _rarityColors = {
  'common':        Color(0xFF8F8F8F),
  'uncommon':      Color(0xFF2ECC40),
  'rare':          Color(0xFF0077FF),
  'epic':          Color(0xFF9B59B6),
  'legendary':     Color(0xFFFF8C00),
  'mythic':        Color(0xFFFFD700),
  'exotic':        Color(0xFF00E5FF),
  'transcendent':  Color(0xFFFF1744),
  'slurp':         Color(0xFF00E5FF),
  'gaminglegends': Color(0xFF6200EA),
  'shadow':        Color(0xFF616161),
  'icon':          Color(0xFF1DE9B6),
  'marvel':        Color(0xFFFF1744),
  'dc':            Color(0xFF1565C0),
  'starwars':      Color(0xFFFFD600),
};

Color _rarityColor(String rarity) =>
    _rarityColors[rarity.toLowerCase()] ?? const Color(0xFF8F8F8F);

// ══════════════════════════════════════════════════════════════
// SCREEN
// ══════════════════════════════════════════════════════════════

class FortniteShopScreen extends StatefulWidget {
  const FortniteShopScreen({super.key});

  @override
  State<FortniteShopScreen> createState() => _FortniteShopScreenState();
}

class _FortniteShopScreenState extends State<FortniteShopScreen> {
  late final ShopService _service;
  _Filter _filter = _Filter.all;
  _Sort   _sort   = _Sort.shopOrder;

  @override
  void initState() {
    super.initState();
    _service = ShopService();
    _service.addListener(_onUpdate);
  }

  @override
  void dispose() {
    _service.removeListener(_onUpdate);
    _service.dispose();
    super.dispose();
  }

  void _onUpdate() { if (mounted) setState(() {}); }

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  // ── Daten aufbereiten ─────────────────────────────────
  List<ShopEntry> _getFiltered() {
    final all = _service.data?.entries ?? [];
    var result = all.where((e) => _matchesFilter(e, _filter)).toList();
    _sortList(result, _sort);
    return result;
  }

  bool get _isDefault => _filter == _Filter.all && _sort == _Sort.shopOrder;

  // ── Sort-Sheet ────────────────────────────────────────
  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _SortSheet(
        current: _sort,
        onSelected: (s) {
          setState(() => _sort = s);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: const Color(0xFF07020F),
      body: OrbitBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Fester Header (Back + Titel + Refresh) ──
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
                      child: Text(
                        l10n.shopTitle,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _service.loading ? null : _service.fetch,
                      icon: _service.loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Icon(Icons.refresh,
                              color: Colors.white.withOpacity(0.80)),
                    ),
                  ],
                ),
              ),

              // ── Status-Zeile ────────────────────────────
              if (_service.data != null)
                Padding(
                  padding: const EdgeInsets.only(left: 20, bottom: 4),
                  child: Text(
                    l10n.shopUpdatedAt(
                      _formatTime(_service.data!.fetchedAt),
                      _service.data!.entries.length,
                    ),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.40),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

              // ── Inhalt (mit scrollendem Filter+Sort) ────
              Expanded(child: _buildBody(l10n)),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  Widget _buildBody(AppLocalizations l10n) {
    if (_service.loading && _service.data == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Color(0xFF9C6FFF)),
            const SizedBox(height: 16),
            Text(l10n.shopLoading,
                style: const TextStyle(color: Colors.white54, fontSize: 15)),
          ],
        ),
      );
    }
    if (_service.error != null && _service.data == null) {
      return _ErrorView(
          error: _service.error!, onRetry: _service.fetch, l10n: l10n);
    }
    if (_service.data == null || _service.data!.entries.isEmpty) {
      return _ErrorView(
          error: l10n.shopEmpty, onRetry: _service.fetch, l10n: l10n);
    }

    final filtered = _getFiltered();

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ── Filter-Chips (scrollt weg) ──────────────────
        SliverToBoxAdapter(
          child: _FilterRow(
            current: _filter,
            onChanged: (f) => setState(() => _filter = f),
          ),
        ),

        // ── Sort-Zeile (scrollt weg) ────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
            child: _SortRow(
              sort: _sort,
              count: filtered.length,
              onTap: _showSortSheet,
            ),
          ),
        ),

        // ── Inhalt ──────────────────────────────────────
        if (filtered.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Text(
                l10n.noResults,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.45), fontSize: 16),
              ),
            ),
          )
        else if (_isDefault)
          // Nach Sektionen gegliedert (Standard)
          ..._buildSectionSlivers(_service.data!.bySection)
        else
          // Flache Liste (bei aktivem Filter oder Sort)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.72,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) => _ShopCard(entry: filtered[i]),
                childCount: filtered.length,
              ),
            ),
          ),
      ],
    );
  }

  List<Widget> _buildSectionSlivers(Map<String, List<ShopEntry>> sections) {
    final slivers = <Widget>[];
    for (final sec in sections.entries) {
      // Section-Header
      slivers.add(SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
          child: Text(
            sec.key.toUpperCase(),
            style: TextStyle(
              color: Colors.white.withOpacity(0.45),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ));
      // Grid
      slivers.add(SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.72,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, i) => _ShopCard(entry: sec.value[i]),
            childCount: sec.value.length,
          ),
        ),
      ));
    }
    slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 32)));
    return slivers;
  }
}

// ══════════════════════════════════════════════════════════════
// FILTER-CHIPS ZEILE
// ══════════════════════════════════════════════════════════════

class _FilterRow extends StatelessWidget {
  final _Filter current;
  final ValueChanged<_Filter> onChanged;

  const _FilterRow({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _filterGroups.length,
        itemBuilder: (context, gi) {
          final group = _filterGroups[gi];
          final groupLabel = group.$1;
          final filters   = group.$2;

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Gruppen-Separator (außer bei der ersten Gruppe)
              if (gi > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Container(
                    width: 1,
                    height: 24,
                    color: Colors.white.withOpacity(0.15),
                  ),
                ),
              // Gruppen-Label
              if (groupLabel.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(
                    groupLabel,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.35),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              // Filter-Chips
              ...filters.map((f) {
                final active = current == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () => onChanged(f),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 13, vertical: 7),
                      decoration: BoxDecoration(
                        color: active
                            ? const Color(0xFF7C4DFF).withOpacity(0.85)
                            : Colors.white.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: active
                              ? const Color(0xFF9C6FFF)
                              : Colors.white.withOpacity(0.12),
                        ),
                      ),
                      child: Text(
                        _filterLabel[f]!,
                        style: TextStyle(
                          color: active
                              ? Colors.white
                              : Colors.white.withOpacity(0.60),
                          fontSize: 12,
                          fontWeight:
                              active ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// SORT-ZEILE
// ══════════════════════════════════════════════════════════════

class _SortRow extends StatelessWidget {
  final _Sort sort;
  final int count;
  final VoidCallback onTap;

  const _SortRow({required this.sort, required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Icon(Icons.sort_rounded,
                size: 16, color: Colors.white.withOpacity(0.50)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _sortLabel[sort]!,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.70),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '$count',
              style: TextStyle(
                color: Colors.white.withOpacity(0.35),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.keyboard_arrow_down_rounded,
                size: 18, color: Colors.white.withOpacity(0.40)),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// SORT-BOTTOM-SHEET
// ══════════════════════════════════════════════════════════════

class _SortSheet extends StatelessWidget {
  final _Sort current;
  final ValueChanged<_Sort> onSelected;

  const _SortSheet({required this.current, required this.onSelected});

  @override
  Widget build(BuildContext context) {
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
            'SORTIERUNG',
            style: TextStyle(
              color: Colors.white.withOpacity(0.40),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          const Divider(color: Colors.white12, height: 1),
          ..._Sort.values.map((s) {
            final isSelected = s == current;
            return InkWell(
              onTap: () => onSelected(s),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _sortLabel[s]!,
                        style: TextStyle(
                          color: isSelected
                              ? const Color(0xFF9C6FFF)
                              : Colors.white.withOpacity(0.80),
                          fontWeight: isSelected
                              ? FontWeight.w800
                              : FontWeight.w500,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    if (isSelected)
                      const Icon(Icons.check_circle_rounded,
                          color: Color(0xFF9C6FFF), size: 20),
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

// ══════════════════════════════════════════════════════════════
// SHOP-KARTE
// ══════════════════════════════════════════════════════════════

class _ShopCard extends StatelessWidget {
  final ShopEntry entry;
  const _ShopCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final accentColor = _rarityColor(entry.rarityValue);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.09),
            Colors.white.withOpacity(0.03),
          ],
        ),
        border: Border.all(color: accentColor.withOpacity(0.45), width: 1.2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          accentColor.withOpacity(0.22),
                          const Color(0xFF07020F),
                        ],
                      ),
                    ),
                  ),
                  if (entry.imageUrl != null)
                    Image.network(
                      entry.imageUrl!,
                      fit: BoxFit.contain,
                      cacheWidth: 400,
                      errorBuilder: (_, __, ___) => const _NoImage(),
                      loadingBuilder: (_, child, progress) => progress == null
                          ? child
                          : Center(
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: accentColor.withOpacity(0.60),
                                ),
                              ),
                            ),
                    )
                  else
                    const _NoImage(),
                  if (entry.isOnSale)
                    Positioned(
                      top: 7, right: 7,
                      child: _Badge(label: 'SALE', color: Colors.red.shade600),
                    ),
                  if (entry.isBundle)
                    Positioned(
                      top: 7, left: 7,
                      child: _Badge(label: 'BUNDLE', color: Colors.purple.shade700),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.displayName.isEmpty ? '???' : entry.displayName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      height: 1.2,
                    ),
                  ),
                  if (entry.typeDisplay.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      entry.typeDisplay,
                      style: TextStyle(
                        color: accentColor.withOpacity(0.85),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _VBucksIcon(),
                      const SizedBox(width: 5),
                      Text(
                        '${entry.finalPrice}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                      if (entry.isOnSale) ...[
                        const SizedBox(width: 6),
                        Text(
                          '${entry.regularPrice}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.38),
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// HILFS-WIDGETS
// ══════════════════════════════════════════════════════════════

class _NoImage extends StatelessWidget {
  const _NoImage();
  @override
  Widget build(BuildContext context) => Icon(
        Icons.image_not_supported_outlined,
        color: Colors.white.withOpacity(0.15),
        size: 36,
      );
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
          ),
        ),
      );
}

class _VBucksIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF00C8FF).withOpacity(0.20),
          border: Border.all(
              color: const Color(0xFF00C8FF).withOpacity(0.60), width: 1),
        ),
        child: const Center(
          child: Text('V',
              style: TextStyle(
                color: Color(0xFF00C8FF),
                fontSize: 9,
                fontWeight: FontWeight.w900,
              )),
        ),
      );
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  final AppLocalizations l10n;
  const _ErrorView(
      {required this.error, required this.onRetry, required this.l10n});
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.storefront_outlined,
                  color: Colors.white24, size: 52),
              const SizedBox(height: 16),
              Text(
                l10n.shopError,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.75),
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                error,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.40), fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onRetry,
                style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF7C4DFF)),
                icon: const Icon(Icons.refresh),
                label: Text(l10n.shopRetry),
              ),
            ],
          ),
        ),
      );
}
