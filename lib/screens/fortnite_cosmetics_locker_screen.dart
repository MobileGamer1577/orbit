import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/cosmetic_item.dart';
import '../storage/collection_store.dart';
import '../storage/cosmetic_meta_store.dart';
import '../theme/orbit_theme.dart';
import '../widgets/cosmetic_detail_sheet.dart';
import '../widgets/orbit_glass_card.dart';

const _kCat = CollectionStore.categoryCosmetic;

// Rarity-Farben
const Map<String, Color> _rarityColors = {
  'common': Color(0xFF8F8F8F), 'uncommon': Color(0xFF2ECC40),
  'rare': Color(0xFF0077FF), 'epic': Color(0xFF9B59B6),
  'legendary': Color(0xFFFF8C00), 'mythic': Color(0xFFFFD700),
  'exotic': Color(0xFF00E5FF), 'icon': Color(0xFF1DE9B6),
  'gaminglegends': Color(0xFF6200EA), 'marvel': Color(0xFFFF1744),
  'dc': Color(0xFF1565C0), 'starwars': Color(0xFFFFD600),
  'slurp': Color(0xFF00E5FF),
};
Color _rc(String r) => _rarityColors[r.toLowerCase()] ?? const Color(0xFF8F8F8F);

class FortniteCosmeticsLockerScreen extends StatefulWidget {
  final CollectionStore collection;

  /// [wishlistMode] = true → Wunschliste, false → Spind
  final bool wishlistMode;

  const FortniteCosmeticsLockerScreen({
    super.key,
    required this.collection,
    this.wishlistMode = false,
  });

  @override
  State<FortniteCosmeticsLockerScreen> createState() => _State();
}

class _State extends State<FortniteCosmeticsLockerScreen> {
  final _ctrl = TextEditingController();
  String _q = '';

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() => setState(() => _q = _ctrl.text.trim().toLowerCase()));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  List<CosmeticItem> _items() {
    final ids = widget.wishlistMode
        ? widget.collection.wishlist(_kCat)
        : widget.collection.owned(_kCat);
    var list = CosmeticMetaStore.getMultiple(ids);
    if (_q.isNotEmpty) {
      list = list.where((i) =>
        i.name.toLowerCase().contains(_q) ||
        i.typeDisplay.toLowerCase().contains(_q)).toList();
    }
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final l10n    = context.l10n;
    final title   = widget.wishlistMode ? l10n.filterWishlist : l10n.hubLocker;
    final subtitle = widget.wishlistMode
        ? l10n.cosmeticsSubtitleWishlist
        : l10n.cosmeticsSubtitleOwned;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: OrbitBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ───────────────────────────────
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: const TextStyle(
                            fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white)),
                          Text(subtitle, style: TextStyle(
                            color: Colors.white.withOpacity(0.50), fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // ── Suche ─────────────────────────────────
                OrbitGlassCard(
                  child: TextField(
                    controller: _ctrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: l10n.lockerSearchHint,
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.40)),
                      prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.55)),
                      suffixIcon: _q.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, color: Colors.white.withOpacity(0.55)),
                              onPressed: () => _ctrl.clear())
                          : null,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // ── Grid ──────────────────────────────────
                Expanded(
                  child: AnimatedBuilder(
                    animation: widget.collection,
                    builder: (context, _) {
                      final items = _items();
                      if (items.isEmpty) {
                        return _EmptyState(
                          wishlistMode: widget.wishlistMode, l10n: l10n);
                      }
                      return GridView.builder(
                        physics: const BouncingScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.72,
                        ),
                        itemCount: items.length,
                        itemBuilder: (context, i) => _LockerCard(
                          item: items[i],
                          collection: widget.collection,
                          onTap: () => showCosmeticDetailSheet(
                            context,
                            item: items[i],
                            collection: widget.collection,
                          ),
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

// ─────────────────────────────────────────────────────────────
// Grid-Karte
// ─────────────────────────────────────────────────────────────

class _LockerCard extends StatelessWidget {
  final CosmeticItem item;
  final CollectionStore collection;
  final VoidCallback onTap;

  const _LockerCard({required this.item, required this.collection, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final accent = _rc(item.rarityValue);
    final owned  = collection.isOwned(_kCat, item.id);
    final wished = collection.isWished(_kCat, item.id);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Colors.white.withOpacity(0.09), Colors.white.withOpacity(0.03)],
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
                          begin: Alignment.topCenter, end: Alignment.bottomCenter,
                          colors: [accent.withOpacity(0.22), const Color(0xFF07020F)],
                        ),
                      ),
                    ),
                    if (item.imageUrl != null)
                      Image.network(item.imageUrl!, fit: BoxFit.contain,
                          cacheWidth: 300,
                          errorBuilder: (_, __, ___) => _NoImg())
                    else
                      _NoImg(),
                    if (owned || wished)
                      Positioned(
                        top: 6, right: 6,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (owned)  const Icon(Icons.check_circle, color: Color(0xFF00E676), size: 15),
                            if (wished) const Icon(Icons.favorite,     color: Color(0xFFFF4081), size: 15),
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
                    Text(item.name.isEmpty ? '???' : item.name,
                        maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white,
                            fontWeight: FontWeight.w800, fontSize: 13, height: 1.2)),
                    if (item.typeDisplay.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(item.typeDisplay, style: TextStyle(
                          color: accent.withOpacity(0.85),
                          fontSize: 11, fontWeight: FontWeight.w600)),
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

class _NoImg extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Icon(
      Icons.image_not_supported_outlined,
      color: Colors.white.withOpacity(0.15), size: 32);
}

// ─────────────────────────────────────────────────────────────
// Leer-Zustand
// ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool wishlistMode;
  final AppLocalizations l10n;
  const _EmptyState({required this.wishlistMode, required this.l10n});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            wishlistMode ? Icons.favorite_border : Icons.inventory_2_outlined,
            color: Colors.white.withOpacity(0.20), size: 52),
          const SizedBox(height: 16),
          Text(
            wishlistMode ? l10n.cosmeticsWishlistEmpty : l10n.cosmeticsLockerEmpty,
            style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 15),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}
