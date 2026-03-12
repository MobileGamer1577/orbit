import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// ─────────────────────────────────────────────────────────
// Modelle
// ─────────────────────────────────────────────────────────

class ShopEntry {
  final int finalPrice;
  final int regularPrice;
  final String? bundleName;
  final String sectionName;
  final List<ShopItem> items;

  const ShopEntry({
    required this.finalPrice,
    required this.regularPrice,
    this.bundleName,
    required this.sectionName,
    required this.items,
  });

  bool get isBundle => bundleName != null && bundleName!.isNotEmpty;
  bool get isOnSale => finalPrice < regularPrice;

  String get displayName {
    if (isBundle) return bundleName!;
    if (items.isNotEmpty) return items.first.name;
    return '???';
  }

  String? imageFor(Map<String, CosmeticImages> imgMap) {
    if (items.isEmpty) return null;
    final item = items.first;
    final direct = item.featuredImage ?? item.iconImage ?? item.smallIconImage;
    if (direct != null) return direct;
    final ci = imgMap[item.id];
    return ci?.featured ?? ci?.icon ?? ci?.smallIcon;
  }

  ShopItem? get primaryItem => items.isNotEmpty ? items.first : null;

  factory ShopEntry.fromJson(Map<String, dynamic> j) {
    String? bundleName;
    final bundle = j['bundle'];
    if (bundle is Map) bundleName = bundle['name'] as String?;

    String sectionName = 'Shop';
    final section = j['section'];
    if (section is Map) {
      sectionName = (section['name'] as String?) ?? 'Shop';
    } else if (section is String && section.isNotEmpty) {
      sectionName = section;
    }
    if (sectionName == 'Shop') {
      final cats = j['categories'];
      if (cats is List && cats.isNotEmpty) sectionName = cats.first.toString();
    }

    final rawItems = j['items'];
    final List<ShopItem> items = rawItems is List
        ? rawItems.whereType<Map>()
            .map((m) => ShopItem.fromJson(Map<String, dynamic>.from(m)))
            .toList()
        : [];

    return ShopEntry(
      finalPrice:
          _toInt(j['finalPrice']) ?? _toInt(j['price']) ?? 0,
      regularPrice: _toInt(j['regularPrice']) ??
          _toInt(j['finalPrice']) ??
          _toInt(j['price']) ??
          0,
      bundleName:  bundleName,
      sectionName: sectionName,
      items:       items,
    );
  }
}

class ShopItem {
  final String id;
  final String name;
  final String typeDisplay;
  final String rarityValue;
  final String rarityDisplay;
  final String? iconImage;
  final String? featuredImage;
  final String? smallIconImage;

  const ShopItem({
    required this.id,
    required this.name,
    required this.typeDisplay,
    required this.rarityValue,
    required this.rarityDisplay,
    this.iconImage,
    this.featuredImage,
    this.smallIconImage,
  });

  factory ShopItem.fromJson(Map<String, dynamic> j) {
    String typeDisplay = '';
    final type = j['type'];
    if (type is Map) {
      typeDisplay =
          ((type['displayValue'] ?? type['value']) as String?) ?? '';
    } else if (type is String) {
      typeDisplay = type;
    }

    String rarityValue   = 'common';
    String rarityDisplay = '';
    final rarity = j['rarity'];
    if (rarity is Map) {
      rarityValue   = (rarity['value']        as String?) ?? 'common';
      rarityDisplay = (rarity['displayValue'] as String?) ?? '';
    } else if (rarity is String) {
      rarityValue = rarity;
    }

    String? iconImage, featuredImage, smallIconImage;
    final images = j['images'];
    if (images is Map) {
      iconImage      = images['icon']          as String?;
      featuredImage  = images['featured']      as String?;
      smallIconImage = images['smallIcon']     as String?
                    ?? images['featuredSmall'] as String?
                    ?? images['background']    as String?;
    }

    return ShopItem(
      id:             j['id']   as String? ?? '',
      name:           j['name'] as String? ?? '???',
      typeDisplay:    typeDisplay,
      rarityValue:    rarityValue,
      rarityDisplay:  rarityDisplay,
      iconImage:      iconImage,
      featuredImage:  featuredImage,
      smallIconImage: smallIconImage,
    );
  }
}

class CosmeticImages {
  final String? smallIcon;
  final String? icon;
  final String? featured;

  const CosmeticImages({this.smallIcon, this.icon, this.featured});

  factory CosmeticImages.fromJson(Map<String, dynamic> j) {
    final images = j['images'];
    if (images is Map) {
      return CosmeticImages(
        smallIcon: images['smallIcon'] as String?,
        icon:      images['icon']      as String?,
        featured:  images['featured']  as String?,
      );
    }
    return const CosmeticImages();
  }
}

class ShopData {
  final List<ShopEntry> entries;
  final Map<String, CosmeticImages> cosmeticImages;
  final DateTime fetchedAt;

  // ── Debug-Felder ─────────────────────────────────────
  final String debugFirstEntry;
  final String debugFirstItem;
  final String debugCosmeticsCount;

  const ShopData({
    required this.entries,
    required this.cosmeticImages,
    required this.fetchedAt,
    this.debugFirstEntry     = '',
    this.debugFirstItem      = '',
    this.debugCosmeticsCount = '',
  });

  Map<String, List<ShopEntry>> get bySection {
    final map = <String, List<ShopEntry>>{};
    for (final e in entries) {
      map.putIfAbsent(e.sectionName, () => []).add(e);
    }
    return map;
  }
}

// ─────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────
int? _toInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

Map<String, String> get _headers => const {
  'Authorization': '135f01ed-1a5e-40df-b8b6-4b2c97f47151',
  'Accept':        'application/json',
  'User-Agent':    'Orbit/1.0',
};

// ─────────────────────────────────────────────────────────
// Service
// ─────────────────────────────────────────────────────────
class ShopService extends ChangeNotifier {
  static const _shopUrl =
      'https://fortnite-api.com/v2/shop?language=de';
  static const _cosmeticsUrl =
      'https://fortnite-api.com/v2/cosmetics/br?language=de';

  ShopData? _data;
  bool      _loading = false;
  String?   _error;
  Timer?    _timer;

  ShopData? get data    => _data;
  bool      get loading => _loading;
  String?   get error   => _error;

  ShopService() {
    fetch();
    _scheduleHourlyRefresh();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _scheduleHourlyRefresh() {
    _timer?.cancel();
    final now      = DateTime.now();
    final nextHour = DateTime(now.year, now.month, now.day, now.hour + 1);
    _timer = Timer(nextHour.difference(now), () {
      fetch();
      _timer = Timer.periodic(const Duration(hours: 1), (_) => fetch());
    });
  }

  Future<void> fetch() async {
    if (_loading) return;
    _loading = true;
    _error   = null;
    notifyListeners();

    try {
      // ── Shop + Cosmetics gleichzeitig laden ──────────────
      final results = await Future.wait([
        http
            .get(Uri.parse(_shopUrl), headers: _headers)
            .timeout(const Duration(seconds: 20)),
        http
            .get(Uri.parse(_cosmeticsUrl), headers: _headers)
            .timeout(const Duration(seconds: 45)),
      ]);

      final shopRes      = results[0];
      final cosmeticsRes = results[1];

      if (shopRes.statusCode != 200) {
        throw Exception('Shop HTTP ${shopRes.statusCode}');
      }

      // ── Shop parsen ──────────────────────────────────────
      final shopJson = jsonDecode(shopRes.body) as Map<String, dynamic>;
      final dataVal  = shopJson['data'];

      List<Map<String, dynamic>> rawEntries = [];

      if (dataVal is Map) {
        final shopMap    = Map<String, dynamic>.from(dataVal);
        final entriesRaw = shopMap['entries'];
        if (entriesRaw is List && entriesRaw.isNotEmpty) {
          rawEntries = entriesRaw
              .whereType<Map>()
              .map((m) => Map<String, dynamic>.from(m))
              .toList();
        }
        if (rawEntries.isEmpty) {
          for (final key in [
            'featured', 'daily', 'specialFeatured', 'specialDaily'
          ]) {
            final sec = shopMap[key];
            if (sec is Map) {
              final se = sec['entries'];
              if (se is List) {
                rawEntries.addAll(se
                    .whereType<Map>()
                    .map((m) => Map<String, dynamic>.from(m)));
              }
            }
          }
        }
      } else if (dataVal is List) {
        rawEntries = dataVal
            .whereType<Map>()
            .map((m) => Map<String, dynamic>.from(m))
            .toList();
      }

      // ── Debug: ersten Eintrag + erstes Item analysieren ──
      String debugFirstEntry = '';
      String debugFirstItem  = '';
      if (rawEntries.isNotEmpty) {
        final fe = rawEntries.first;
        debugFirstEntry = 'entry keys: ${fe.keys.toList()}';

        final rawItems = fe['items'];
        if (rawItems is List && rawItems.isNotEmpty) {
          final fi = Map<String, dynamic>.from(rawItems.first as Map);
          debugFirstItem = 'item keys: ${fi.keys.toList()}';

          final imgs = fi['images'];
          if (imgs is Map) {
            debugFirstItem += '\nimages keys: ${imgs.keys.toList()}';
            final vals = imgs.entries
                .where((e) => e.value != null && e.value.toString().isNotEmpty)
                .map((e) {
                  final v = e.value.toString();
                  return '${e.key}: ${v.substring(0, v.length.clamp(0, 80))}';
                })
                .join('\n');
            debugFirstItem += '\n$vals';
          } else {
            debugFirstItem += '\nimages = $imgs';
          }
        } else {
          debugFirstItem = 'items = $rawItems';
        }
      }

      final entries = rawEntries.map(ShopEntry.fromJson).toList();

      // ── Cosmetics-Bilder parsen ──────────────────────────
      final cosmeticImages = <String, CosmeticImages>{};
      String debugCosCount  = 'HTTP ${cosmeticsRes.statusCode}';

      if (cosmeticsRes.statusCode == 200) {
        try {
          final cosJson = jsonDecode(cosmeticsRes.body) as Map<String, dynamic>;
          final cosData = cosJson['data'];

          Iterable<dynamic> cosmetics;
          if (cosData is List) {
            // /v2/cosmetics/br liefert direkt eine Liste
            cosmetics = cosData;
          } else if (cosData is Map) {
            final br = cosData['br'];
            cosmetics = br is List
                ? br
                : cosData.values
                    .expand((v) => v is List ? v : <dynamic>[]);
          } else {
            cosmetics = <dynamic>[];
          }

          for (final raw in cosmetics) {
            if (raw is Map) {
              final id = raw['id'] as String?;
              if (id != null && id.isNotEmpty) {
                cosmeticImages[id] = CosmeticImages.fromJson(
                    Map<String, dynamic>.from(raw));
              }
            }
          }
          debugCosCount = '${cosmeticImages.length} geladen';

          // Debug: prüfe ob erste Shop-Item-ID in cosmeticImages ist
          if (entries.isNotEmpty &&
              entries.first.items.isNotEmpty) {
            final firstId = entries.first.items.first.id;
            final found   = cosmeticImages[firstId];
            debugCosCount +=
                '\nID "$firstId" → ${found == null ? "NOT FOUND" : "icon=${found.icon?.substring(0, 60) ?? "null"}"}';
          }
        } catch (e) {
          debugCosCount = 'parse error: $e';
        }
      }

      _data = ShopData(
        entries:             entries,
        cosmeticImages:      cosmeticImages,
        fetchedAt:           DateTime.now(),
        debugFirstEntry:     debugFirstEntry,
        debugFirstItem:      debugFirstItem,
        debugCosmeticsCount: debugCosCount,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
