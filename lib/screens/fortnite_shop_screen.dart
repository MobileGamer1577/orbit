import 'package:flutter/material.dart';

import '../services/shop_service.dart';
import '../theme/orbit_theme.dart';
import '../widgets/orbit_glass_card.dart';

const _rarityColors = {
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

class FortniteShopScreen extends StatefulWidget {
  const FortniteShopScreen({super.key});

  @override
  State<FortniteShopScreen> createState() => _FortniteShopScreenState();
}

class _FortniteShopScreenState extends State<FortniteShopScreen> {
  late final ShopService _service;
  bool _showDebug = true; // temporär an — nach dem Fix ausschalten

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

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:'
      '${dt.minute.toString().padLeft(2, '0')} Uhr';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07020F),
      body: OrbitBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ─────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 8, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.arrow_back,
                          color: Colors.white.withOpacity(0.90)),
                    ),
                    const SizedBox(width: 4),
                    const Expanded(
                      child: Text(
                        'Item Shop',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    // Debug-Toggle
                    IconButton(
                      onPressed: () =>
                          setState(() => _showDebug = !_showDebug),
                      icon: Icon(
                        Icons.bug_report_outlined,
                        color: _showDebug
                            ? const Color(0xFF9C6FFF)
                            : Colors.white38,
                        size: 22,
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

              // ── Statuszeile ─────────────────────────────
              if (_service.data != null)
                Padding(
                  padding: const EdgeInsets.only(left: 20, bottom: 4),
                  child: Text(
                    'Aktualisiert: ${_formatTime(_service.data!.fetchedAt)}'
                    ' • ${_service.data!.entries.length} Einträge',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.40),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

              // ── Debug-Panel ─────────────────────────────
              if (_showDebug && _service.data != null)
                Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.60),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xFF9C6FFF).withOpacity(0.40)),
                  ),
                  child: Text(
                    '${_service.data!.debugFirstEntry}\n'
                    '${_service.data!.debugFirstItem}\n'
                    '--- cosmetics ---\n'
                    '${_service.data!.debugCosmeticsCount}',
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 10,
                      fontFamily: 'monospace',
                      height: 1.5,
                    ),
                  ),
                ),

              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_service.loading && _service.data == null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFF9C6FFF)),
            SizedBox(height: 16),
            Text('Shop wird geladen…',
                style: TextStyle(color: Colors.white54, fontSize: 15)),
          ],
        ),
      );
    }

    if (_service.error != null && _service.data == null) {
      return _ErrorView(error: _service.error!, onRetry: _service.fetch);
    }

    if (_service.data == null || _service.data!.entries.isEmpty) {
      return _ErrorView(
          error: 'Keine Einträge gefunden.', onRetry: _service.fetch);
    }

    final sections = _service.data!.bySection;
    final imgMap   = _service.data!.cosmeticImages;

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      itemCount: sections.length,
      itemBuilder: (context, si) {
        final sectionName = sections.keys.elementAt(si);
        final entries     = sections[sectionName]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text(
              sectionName.toUpperCase(),
              style: TextStyle(
                color: Colors.white.withOpacity(0.45),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.72,
              ),
              itemCount: entries.length,
              itemBuilder: (context, i) =>
                  _ShopCard(entry: entries[i], imgMap: imgMap),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────
class _ShopCard extends StatelessWidget {
  final ShopEntry                   entry;
  final Map<String, CosmeticImages> imgMap;

  const _ShopCard({required this.entry, required this.imgMap});

  @override
  Widget build(BuildContext context) {
    final rarity      = entry.primaryItem?.rarityValue ?? 'common';
    final accentColor = _rarityColor(rarity);
    final imageUrl    = entry.imageFor(imgMap);

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
        border:
            Border.all(color: accentColor.withOpacity(0.45), width: 1.2),
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
                  if (imageUrl != null)
                    Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) =>
                          const _NoImage(),
                      loadingBuilder: (_, child, progress) =>
                          progress == null
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
                      child: _Badge(
                          label: 'SALE', color: Colors.red.shade600),
                    ),
                  if (entry.isBundle)
                    Positioned(
                      top: 7, left: 7,
                      child: _Badge(
                          label: 'BUNDLE',
                          color: Colors.purple.shade700),
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
                    entry.displayName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      height: 1.2,
                    ),
                  ),
                  if (entry.primaryItem?.typeDisplay.isNotEmpty ==
                      true) ...[
                    const SizedBox(height: 2),
                    Text(
                      entry.primaryItem!.typeDisplay,
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

// ─────────────────────────────────────────────────────────
class _NoImage extends StatelessWidget {
  const _NoImage();
  @override
  Widget build(BuildContext context) => const Icon(
        Icons.image_not_supported_outlined,
        color: Colors.white12,
        size: 36,
      );
}

class _Badge extends StatelessWidget {
  final String label;
  final Color  color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8)),
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
              color: const Color(0xFF00C8FF).withOpacity(0.60),
              width: 1),
        ),
        child: const Center(
          child: Text('V',
              style: TextStyle(
                  color: Color(0xFF00C8FF),
                  fontSize: 9,
                  fontWeight: FontWeight.w900)),
        ),
      );
}

class _ErrorView extends StatelessWidget {
  final String       error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.storefront_outlined,
                  color: Colors.white24, size: 52),
              const SizedBox(height: 16),
              Text('Shop konnte nicht geladen werden',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.75),
                      fontSize: 17,
                      fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(error,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.40),
                      fontSize: 12),
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onRetry,
                style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF7C4DFF)),
                icon: const Icon(Icons.refresh),
                label: const Text('Erneut versuchen'),
              ),
            ],
          ),
        ),
      );
}
