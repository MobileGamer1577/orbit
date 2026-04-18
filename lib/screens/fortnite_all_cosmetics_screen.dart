import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../l10n/app_localizations.dart';
import '../models/cosmetic_item.dart';
import '../storage/collection_store.dart';
import '../theme/orbit_theme.dart';
import '../widgets/cosmetic_detail_sheet.dart';
import '../widgets/orbit_glass_card.dart';
import '../config/api_keys.dart';

// ══════════════════════════════════════════════════════════════
// KATEGORIE (intern, kein UI mehr)
// ══════════════════════════════════════════════════════════════

enum _CosmeticCategory { br, tracks, instruments, cars, lego, beans }

const Map<_CosmeticCategory, String> _catEndpoint = {
  _CosmeticCategory.br: 'https://fortnite-api.com/v2/cosmetics/br',
  _CosmeticCategory.tracks: 'https://fortnite-api.com/v2/cosmetics/tracks',
  _CosmeticCategory.instruments:
      'https://fortnite-api.com/v2/cosmetics/instruments',
  _CosmeticCategory.cars: 'https://fortnite-api.com/v2/cosmetics/cars',
  _CosmeticCategory.lego: 'https://fortnite-api.com/v2/cosmetics/lego',
  _CosmeticCategory.beans: 'https://fortnite-api.com/v2/cosmetics/beans',
};

// ══════════════════════════════════════════════════════════════
// RARITY FARBEN
// ══════════════════════════════════════════════════════════════

const Map<String, Color> _rarityColors = {
  'common': Color(0xFF8F8F8F),
  'uncommon': Color(0xFF2ECC40),
  'rare': Color(0xFF0077FF),
  'epic': Color(0xFF9B59B6),
  'legendary': Color(0xFFFF8C00),
  'mythic': Color(0xFFFFD700),
  'exotic': Color(0xFF00E5FF),
  'icon': Color(0xFF1DE9B6),
  'gaminglegends': Color(0xFF6200EA),
  'marvel': Color(0xFFFF1744),
  'dc': Color(0xFF1565C0),
  'starwars': Color(0xFFFFD600),
  'slurp': Color(0xFF00E5FF),
};

Color _rarityColor(String r) =>
    _rarityColors[r.toLowerCase()] ?? const Color(0xFF8F8F8F);

// ══════════════════════════════════════════════════════════════
// SCREEN
// ══════════════════════════════════════════════════════════════

class FortniteAllCosmeticsScreen extends StatefulWidget {
  final CollectionStore collection;

  const FortniteAllCosmeticsScreen({super.key, required this.collection});

  @override
  State<FortniteAllCosmeticsScreen> createState() =>
      _FortniteAllCosmeticsScreenState();
}

class _FortniteAllCosmeticsScreenState
    extends State<FortniteAllCosmeticsScreen> {
  static const _apiKey = ApiKeys.fortniteApiCom;

  final _CosmeticCategory _category = _CosmeticCategory.br;
  List<CosmeticItem> _items = [];
  List<CosmeticItem> _filtered = [];
  bool _loading = false;
  String? _error;
  String _query = '';
  Timer? _debounce;

  final TextEditingController _searchCtrl = TextEditingController();
  final Map<_CosmeticCategory, List<CosmeticItem>> _cache = {};

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearch);
    _loadCategory(_category);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (mounted)
        setState(() {
          _query = _searchCtrl.text.trim().toLowerCase();
          _applyFilter();
        });
    });
  }

  void _applyFilter() {
    if (_query.isEmpty) {
      _filtered = List.of(_items);
    } else {
      _filtered = _items
          .where(
            (item) =>
                item.name.toLowerCase().contains(_query) ||
                item.id.toLowerCase().contains(_query) ||
                item.typeDisplay.toLowerCase().contains(_query),
          )
          .toList();
    }
  }

  Future<void> _loadCategory(_CosmeticCategory cat) async {
    if (_cache.containsKey(cat)) {
      if (mounted)
        setState(() {
          _items = _cache[cat]!;
          _applyFilter();
        });
      return;
    }

    if (mounted)
      setState(() {
        _loading = true;
        _error = null;
      });

    try {
      final res = await http
          .get(
            Uri.parse(_catEndpoint[cat]!),
            headers: {
              'Authorization': _apiKey,
              'Accept': 'application/json',
              'User-Agent': 'Orbit/1.0',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');

      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final rawData = json['data'];
      final list = rawData is List ? rawData : <dynamic>[];

      final items = list
          .whereType<Map<String, dynamic>>()
          .map((m) {
            switch (cat) {
              case _CosmeticCategory.br:
                return CosmeticItem.fromBrApi(m);
              case _CosmeticCategory.tracks:
                return CosmeticItem.fromTrackApi(m);
              case _CosmeticCategory.instruments:
                return CosmeticItem.fromInstrumentApi(m);
              case _CosmeticCategory.cars:
                return CosmeticItem.fromCarApi(m);
              case _CosmeticCategory.lego:
                return CosmeticItem.fromLegoApi(m);
              case _CosmeticCategory.beans:
                return CosmeticItem.fromBeanApi(m);
            }
          })
          .where((i) => i.name.isNotEmpty)
          .toList();

      items.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      _cache[cat] = items;

      if (mounted)
        setState(() {
          _items = items;
          _applyFilter();
          _loading = false;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          _error = e.toString();
          _loading = false;
        });
    }
  }

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
              // ── Header ─────────────────────────────────
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
                        l10n.cosmeticsAll,
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

              const SizedBox(height: 4),

              // ── Suchfeld ────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: OrbitGlassCard(
                  child: TextField(
                    controller: _searchCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Cosmetics suchen…',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.40),
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Colors.white.withOpacity(0.55),
                      ),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear,
                                color: Colors.white.withOpacity(0.55),
                              ),
                              onPressed: () => _searchCtrl.clear(),
                            )
                          : null,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                ),
              ),

              if (!_loading && _error == null)
                Padding(
                  padding: const EdgeInsets.only(left: 20, top: 8, bottom: 2),
                  child: Text(
                    '${_filtered.length} Items',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.38),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

              // ── Inhalt ──────────────────────────────────
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF9C6FFF),
                        ),
                      )
                    : _error != null
                    ? _ErrorWidget(
                        error: _error!,
                        onRetry: () => _loadCategory(_category),
                      )
                    : _filtered.isEmpty
                    ? Center(
                        child: Text(
                          _query.isEmpty ? 'Keine Einträge' : 'Keine Treffer.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.45),
                            fontSize: 16,
                          ),
                        ),
                      )
                    : AnimatedBuilder(
                        animation: widget.collection,
                        builder: (context, _) => GridView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 0.72,
                              ),
                          itemCount: _filtered.length,
                          itemBuilder: (context, i) => _CosmeticCard(
                            item: _filtered[i],
                            collection: widget.collection,
                            onTap: () => showCosmeticDetailSheet(
                              context,
                              item: _filtered[i],
                              collection: widget.collection,
                            ),
                          ),
                        ),
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
// COSMETIC-KARTE
// ══════════════════════════════════════════════════════════════

class _CosmeticCard extends StatelessWidget {
  final CosmeticItem item;
  final CollectionStore collection;
  final VoidCallback onTap;

  const _CosmeticCard({
    required this.item,
    required this.collection,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = _rarityColor(item.rarityValue);
    final owned = collection.isOwned(CollectionStore.categoryCosmetic, item.id);
    final wished = collection.isWished(
      CollectionStore.categoryCosmetic,
      item.id,
    );

    return GestureDetector(
      onTap: onTap,
      child: Container(
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
          border: Border.all(color: accent.withOpacity(0.45), width: 1.2),
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
                            accent.withOpacity(0.22),
                            const Color(0xFF07020F),
                          ],
                        ),
                      ),
                    ),
                    if (item.imageUrl != null)
                      Image.network(
                        item.imageUrl!,
                        fit: BoxFit.contain,
                        cacheWidth: 300,
                        errorBuilder: (_, __, ___) => const _NoImage(),
                        loadingBuilder: (_, child, progress) => progress == null
                            ? child
                            : Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: accent.withOpacity(0.60),
                                  ),
                                ),
                              ),
                      )
                    else
                      const _NoImage(),
                    if (owned || wished)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (owned)
                              const Icon(
                                Icons.check_circle,
                                color: Color(0xFF00E676),
                                size: 16,
                              ),
                            if (wished)
                              const Icon(
                                Icons.favorite,
                                color: Color(0xFFFF4081),
                                size: 16,
                              ),
                          ],
                        ),
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
                      item.name.isEmpty ? '???' : item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        height: 1.2,
                      ),
                    ),
                    if (item.typeDisplay.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.typeDisplay,
                        style: TextStyle(
                          color: accent.withOpacity(0.85),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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
// HILFS-WIDGETS
// ══════════════════════════════════════════════════════════════

class _NoImage extends StatelessWidget {
  const _NoImage();
  @override
  Widget build(BuildContext context) => Icon(
    Icons.image_not_supported_outlined,
    color: Colors.white.withOpacity(0.15),
    size: 32,
  );
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
          const Icon(Icons.error_outline, color: Colors.white24, size: 48),
          const SizedBox(height: 12),
          Text(
            'Konnte nicht laden',
            style: TextStyle(
              color: Colors.white.withOpacity(0.70),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              color: Colors.white.withOpacity(0.35),
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onRetry,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF7C4DFF),
            ),
            icon: const Icon(Icons.refresh),
            label: const Text('Nochmal'),
          ),
        ],
      ),
    ),
  );
}
