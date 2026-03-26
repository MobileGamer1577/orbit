import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/cosmetic_item.dart';
import '../storage/collection_store.dart';
import '../storage/cosmetic_meta_store.dart';

// ─────────────────────────────────────────────────────────────
// Öffne das Sheet
// ─────────────────────────────────────────────────────────────

Future<void> showCosmeticDetailSheet(
  BuildContext context, {
  required CosmeticItem item,
  required CollectionStore collection,
}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _CosmeticDetailSheet(item: item, collection: collection),
  );
}

// ─────────────────────────────────────────────────────────────
// Rarity-Farben
// ─────────────────────────────────────────────────────────────

const Map<String, Color> _rarityColors = {
  'common':        Color(0xFF8F8F8F),
  'uncommon':      Color(0xFF2ECC40),
  'rare':          Color(0xFF0077FF),
  'epic':          Color(0xFF9B59B6),
  'legendary':     Color(0xFFFF8C00),
  'mythic':        Color(0xFFFFD700),
  'exotic':        Color(0xFF00E5FF),
  'icon':          Color(0xFF1DE9B6),
  'gaminglegends': Color(0xFF6200EA),
  'marvel':        Color(0xFFFF1744),
  'dc':            Color(0xFF1565C0),
  'starwars':      Color(0xFFFFD600),
  'slurp':         Color(0xFF00E5FF),
};

Color _rarityColor(String r) =>
    _rarityColors[r.toLowerCase()] ?? const Color(0xFF8F8F8F);

// ─────────────────────────────────────────────────────────────
// Datum formatieren
// ─────────────────────────────────────────────────────────────

String _fmtDate(String? iso) {
  if (iso == null || iso.isEmpty) return '—';
  try {
    final dt = DateTime.parse(iso).toLocal();
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
  } catch (_) {
    return iso;
  }
}

// ─────────────────────────────────────────────────────────────
// Sheet
// ─────────────────────────────────────────────────────────────

class _CosmeticDetailSheet extends StatefulWidget {
  final CosmeticItem item;
  final CollectionStore collection;

  const _CosmeticDetailSheet({required this.item, required this.collection});

  @override
  State<_CosmeticDetailSheet> createState() => _CosmeticDetailSheetState();
}

class _CosmeticDetailSheetState extends State<_CosmeticDetailSheet> {
  final _cat = CollectionStore.categoryCosmetic;

  bool get _owned  => widget.collection.isOwned (_cat, widget.item.id);
  bool get _wished => widget.collection.isWished(_cat, widget.item.id);

  Future<void> _toggleOwned() async {
    // Metadata speichern bevor wir es zum Spind hinzufügen
    if (!_owned) await CosmeticMetaStore.save(widget.item);
    await widget.collection.toggleOwned(_cat, widget.item.id);
    if (mounted) setState(() {});
  }

  Future<void> _toggleWished() async {
    if (!_wished) await CosmeticMetaStore.save(widget.item);
    await widget.collection.toggleWished(_cat, widget.item.id);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n  = context.l10n;
    final item  = widget.item;
    final accent = _rarityColor(item.rarityValue);
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(left: 12, right: 12, bottom: 12 + bottom),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Material(
          color: const Color(0xFF1A1026).withOpacity(0.97),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header: Bild + Name ───────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ItemImage(url: item.imageUrl, accent: accent),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name.isEmpty ? '???' : item.name,
                            style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w900,
                              fontSize: 18, height: 1.2,
                            ),
                          ),
                          if (item.typeDisplay.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              item.typeDisplay,
                              style: TextStyle(
                                color: accent.withOpacity(0.85),
                                fontWeight: FontWeight.w600, fontSize: 13,
                              ),
                            ),
                          ],
                          const SizedBox(height: 10),
                          // Action Chips
                          Wrap(
                            spacing: 8,
                            children: [
                              _ActionChip(
                                icon:   _owned ? Icons.check_circle : Icons.check_circle_outline,
                                label:  _owned ? l10n.songOwned : l10n.songOwn,
                                active: _owned,
                                color:  const Color(0xFF00E676),
                                onTap:  _toggleOwned,
                              ),
                              _ActionChip(
                                icon:   _wished ? Icons.favorite : Icons.favorite_border,
                                label:  _wished ? l10n.songOnWishlist : l10n.songWishlist,
                                active: _wished,
                                color:  const Color(0xFFFF4081),
                                onTap:  _toggleWished,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                _Divider(),

                // ── Details ───────────────────────────────
                const SizedBox(height: 12),
                _SectionLabel(l10n.songDetails),
                const SizedBox(height: 10),

                if (item.rarityValue.isNotEmpty)
                  _InfoRow(l10n.cosmeticRarity, _rarityLabel(item.rarityValue, l10n), accent: accent),
                if (item.introduction != null && item.introduction!.isNotEmpty)
                  _InfoRow(l10n.cosmeticIntroduced, item.introduction!),
                if (item.addedDate != null)
                  _InfoRow(l10n.songAdded, _fmtDate(item.addedDate)),
                if (item.lastSeen != null)
                  _InfoRow(l10n.cosmeticLastSeen, _fmtDate(item.lastSeen)),
                if (item.setName != null && item.setName!.isNotEmpty)
                  _InfoRow(l10n.cosmeticSet, item.setName!),
                if (item.seriesName != null && item.seriesName!.isNotEmpty)
                  _InfoRow(l10n.cosmeticSeries, item.seriesName!),
                _InfoRow('ID', item.id.isEmpty ? '—' : item.id),

                // ── Beschreibung ──────────────────────────
                if (item.description != null && item.description!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _Divider(),
                  const SizedBox(height: 12),
                  _SectionLabel(l10n.cosmeticDescription),
                  const SizedBox(height: 8),
                  Text(
                    item.description!,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.70),
                      fontSize: 13, height: 1.5, fontWeight: FontWeight.w500,
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

  String _rarityLabel(String value, AppLocalizations l10n) {
    // Seltenheits-Anzeigename (API liefert Englisch)
    switch (value.toLowerCase()) {
      case 'common':        return l10n.rarityCommon;
      case 'uncommon':      return l10n.rarityUncommon;
      case 'rare':          return l10n.rarityRare;
      case 'epic':          return l10n.rarityEpic;
      case 'legendary':     return l10n.rarityLegendary;
      case 'mythic':        return l10n.rarityMythic;
      case 'exotic':        return l10n.rarityExotic;
      case 'icon':          return 'Icon Series';
      case 'gaminglegends': return 'Gaming Legends';
      case 'marvel':        return 'Marvel';
      case 'dc':            return 'DC';
      case 'starwars':      return 'Star Wars';
      default:              return value;
    }
  }
}

// ─────────────────────────────────────────────────────────────
// Hilfs-Widgets
// ─────────────────────────────────────────────────────────────

class _ItemImage extends StatelessWidget {
  final String? url;
  final Color accent;
  const _ItemImage({required this.url, required this.accent});

  @override
  Widget build(BuildContext context) => Container(
    width: 90, height: 90,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(14),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [accent.withOpacity(0.25), const Color(0xFF07020F)],
      ),
      border: Border.all(color: accent.withOpacity(0.45), width: 1.2),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(13),
      child: (url != null && url!.isNotEmpty)
          ? Image.network(url!, fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => _placeholder())
          : _placeholder(),
    ),
  );

  Widget _placeholder() => Icon(Icons.image_not_supported_outlined,
      color: Colors.white.withOpacity(0.25), size: 34);
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon, required this.label,
    required this.active, required this.color, required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(999),
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: active ? color.withOpacity(0.18) : Colors.white.withOpacity(0.07),
        border: Border.all(
          color: active ? color.withOpacity(0.55) : Colors.white.withOpacity(0.12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: active ? color : Colors.white.withOpacity(0.60)),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(
            color: active ? color : Colors.white.withOpacity(0.70),
            fontSize: 12, fontWeight: FontWeight.w700,
          )),
        ],
      ),
    ),
  );
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: TextStyle(
      color: Colors.white.withOpacity(0.40),
      fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2,
    ),
  );
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? accent;
  const _InfoRow(this.label, this.value, {this.accent});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(label, style: TextStyle(
            color: Colors.white.withOpacity(0.45),
            fontWeight: FontWeight.w600, fontSize: 13,
          )),
        ),
        Expanded(child: Text(value, style: TextStyle(
          color: accent ?? Colors.white,
          fontWeight: FontWeight.w700, fontSize: 13,
        ))),
      ],
    ),
  );
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(height: 1, color: Colors.white.withOpacity(0.08));
}
