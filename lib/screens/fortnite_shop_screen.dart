import 'package:flutter/material.dart';

import '../services/shop_service.dart';
import '../theme/orbit_theme.dart';
import '../widgets/orbit_glass_card.dart';

// Seltenheits-Farben (passend zu Fortnite)
const _rarityColors = {
  'common': Color(0xFF8F8F8F),
  'uncommon': Color(0xFF2ECC40),
  'rare': Color(0xFF0077FF),
  'epic': Color(0xFF9B59B6),
  'legendary': Color(0xFFFF8C00),
  'mythic': Color(0xFFFFD700),
  'exotic': Color(0xFF00E5FF),
  'transcendent': Color(0xFFFF1744),
  'slurp': Color(0xFF00E5FF),
  'gaminglegends': Color(0xFF6200EA),
  'shadow': Color(0xFF424242),
  'icon': Color(0xFF1DE9B6),
  'marvel': Color(0xFFFF1744),
  'dc': Color(0xFF1565C0),
  'starwars': Color(0xFFFFD600),
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

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m Uhr';
  }

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
                    // Refresh-Button
                    IconButton(
                      onPressed: _service.loading ? null : _service.fetch,
                      icon: _service.loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              Icons.refresh,
                              color: Colors.white.withOpacity(0.80),
                            ),
                    ),
                  ],
                ),
              ),

              // ── Aktualisierungszeit ──────────────────────
              if (_service.data != null)
                Padding(
                  padding: const EdgeInsets.only(left: 20, bottom: 8),
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

              // ── Inhalt ──────────────────────────────────
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
            Text(
              'Shop wird geladen…',
              style: TextStyle(color: Colors.white54, fontSize: 15),
            ),
          ],
        ),
      );
    }

    if (_service.error != null && _service.data == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off, color: Colors.white38, size: 52),
              const SizedBox(height: 16),
              Text(
                'Shop konnte nicht geladen werden',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.75),
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _service.error!,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.40),
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _service.fetch,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF7C4DFF),
                ),
                icon: const Icon(Icons.refresh),
                label: const Text('Erneut versuchen'),
              ),
            ],
          ),
        ),
      );
    }

    if (_service.data == null) return const SizedBox.shrink();

    final sections = _service.data!.bySection;

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      itemCount: sections.length,
      itemBuilder: (context, si) {
        final sectionName = sections.keys.elementAt(si);
        final entries = sections[sectionName]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 18),
            // Section Header
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
            // Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.72,
              ),
              itemCount: entries.length,
              itemBuilder: (context, i) => _ShopCard(entry: entries[i]),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────
// Shop-Karte
// ─────────────────────────────────────────────────────────
class _ShopCard extends StatelessWidget {
  final ShopEntry entry;

  const _ShopCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final rarity = entry.primaryItem?.rarityValue ?? 'common';
    final accentColor = _rarityColor(rarity);
    final imageUrl = entry.displayImage;
    final isOnSale = entry.finalPrice < entry.regularPrice;

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
        border: Border.all(
          color: accentColor.withOpacity(0.40),
          width: 1.2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Bild
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Hintergrund-Gradient in Rarityfarbe
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          accentColor.withOpacity(0.18),
                          const Color(0xFF07020F),
                        ],
                      ),
                    ),
                  ),

                  // Item-Bild
                  if (imageUrl != null)
                    Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.image_not_supported_outlined,
                        color: Colors.white24,
                        size: 40,
                      ),
                      loadingBuilder: (_, child, progress) {
                        if (progress == null) return child;
                        return Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: accentColor.withOpacity(0.60),
                            ),
                          ),
                        );
                      },
                    )
                  else
                    Icon(Icons.storefront, color: Colors.white24, size: 40),

                  // Sale-Badge
                  if (isOnSale)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.shade600,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'SALE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ),

                  // Bundle-Badge
                  if (entry.isBundle)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade700,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'BUNDLE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Info-Bereich
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
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

                  if (entry.primaryItem?.typeDisplay.isNotEmpty == true) ...[
                    const SizedBox(height: 3),
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

                  // Preis
                  Row(
                    children: [
                      // V-Bucks Icon
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF00C8FF).withOpacity(0.20),
                          border: Border.all(
                            color: const Color(0xFF00C8FF).withOpacity(0.60),
                            width: 1,
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            'V',
                            style: TextStyle(
                              color: Color(0xFF00C8FF),
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${entry.finalPrice}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                      if (isOnSale) ...[
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
