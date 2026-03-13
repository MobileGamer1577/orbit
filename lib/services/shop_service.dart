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
  final String devName;
  final List<ShopTrack> tracks;

  const ShopEntry({
    required this.finalPrice,
    required this.regularPrice,
    this.bundleName,
    required this.sectionName,
    required this.devName,
    required this.tracks,
  });

  bool get isBundle => bundleName != null && bundleName!.isNotEmpty;
  bool get isOnSale => finalPrice < regularPrice;

  String get displayName {
    if (isBundle) return bundleName!;
    if (tracks.isNotEmpty) {
      final n = tracks.first.name;
      // "[VIRTUAL]1 x Songname for 500 V-Bucks" → "Songname"
      if (n.startsWith('[VIRTUAL]')) {
        final m = RegExp(r'\[VIRTUAL\]\d+ x (.+?) for \d+').firstMatch(n);
        if (m != null) return m.group(1)!;
        return n.replaceFirst(RegExp(r'\[VIRTUAL\]\d+ x '), '');
      }
      return n;
    }
    // devName als Fallback, z.B. "BR.Pickaxe.FestivalPickaxe_001" → "FestivalPickaxe 001"
    final last = devName.split('.').last;
    return last.replaceAll('_', ' ');
  }

  String? imageFor(Map<String, CosmeticImages> imgMap) {
    for (final track in tracks) {
      final ci = imgMap[track.id];
      if (ci != null) return ci.featured ?? ci.icon ?? ci.smallIcon;
    }
    return null;
  }

  String get primaryRarity =>
      tracks.isNotEmpty ? tracks.first.rarityValue : 'common';

  String get primaryTypeDisplay =>
      tracks.isNotEmpty ? tracks.first.typeDisplay : '';

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

    final rawTracks = j['tracks'];
    final List<ShopTrack> tracks = rawTracks is List
        ? rawTracks
            .whereType<Map>()
            .map((m) => ShopTrack.fromJson(Map<String, dynamic>.from(m)))
            .toList()
        : [];

    return ShopEntry(
      finalPrice:   _toInt(j['finalPrice'])   ?? _toInt(j['price'])   ?? 0,
      regularPrice: _toInt(j['regularPrice']) ?? _toInt(j['finalPrice']) ?? _toInt(j['price']) ?? 0,
      bundleName:   bundleName,
      sectionName:  sectionName,
      devName:      j['devName'] as String? ?? '',
      tracks:       tracks,
    );
  }
}

class ShopTrack {
  final String id;
  final String name;
  final String typeDisplay;
  final String rarityValue;
  final String rarityDisplay;

  const ShopTrack({
    required this.id,
    required this.name,
    required this.typeDisplay,
    required this.rarityValue,
    required this.rarityDisplay,
  });

  factory ShopTrack.fromJson(Map<String, dynamic> j) {
    String typeDisplay = '';
    final type = j['type'];
    if (type is Map) {
      typeDisplay = ((type['displayValue'] ?? type['value']) as String?) ?? '';
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

    return ShopTrack(
      id:            j['id']   as String? ?? '',
      name:          j['name'] as String? ?? '???',
      typeDisplay:   typeDisplay,
      rarityValue:   rarityValue,
      rarityDisplay: rarityDisplay,
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
  final List<ShopEntry>             entries;
  final Map<String, CosmeticImages> cosmeticImages;
  final DateTime                    fetchedAt;

  const ShopData({
    required this.entries,
    required this.cosmeticImages,
    required this.fetchedAt,
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
int? _toInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

const Map<String, String> _headers = {
  'Authorization': '135f01ed-1a5e-40df-b8b6-4b2c97f47151',
  'Accept':        'application/json',
  'User-Agent':    'Orbit/1.0',
};

// ─────────────────────────────────────────────────────────
// Service
// ─────────────────────────────────────────────────────────
class ShopService extends ChangeNotifier {
  // Shop-Endpoint
  static const _shopUrl = 'https://fortnite-api.com/v2/shop?language=de';

  // ALLE Cosmetic-Typen in einem Call (br + tracks + instruments + lego + cars + beans + …)
  static const _cosmeticsUrl = 'https://fortnite-api.com/v2/cosmetics?language=de';

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
      // Shop + alle Cosmetics gleichzeitig laden
      final results = await Future.wait([
        http.get(Uri.parse(_shopUrl),      headers: _headers)
            .timeout(const Duration(seconds: 20)),
        http.get(Uri.parse(_cosmeticsUrl), headers: _headers)
            .timeout(const Duration(seconds: 60)),
      ]);

      final shopRes      = results[0];
      final cosmeticsRes = results[1];

      if (shopRes.statusCode != 200) throw Exception('Shop HTTP ${shopRes.statusCode}');

      // ── Shop parsen ──────────────────────────────────────
      final shopJson = jsonDecode(shopRes.body) as Map<String, dynamic>;
      final dataVal  = shopJson['data'];
      List<Map<String, dynamic>> rawEntries = [];

      if (dataVal is Map) {
        final shopMap    = Map<String, dynamic>.from(dataVal);
        final entriesRaw = shopMap['entries'];
        if (entriesRaw is List && entriesRaw.isNotEmpty) {
          rawEntries = entriesRaw.whereType<Map>()
              .map((m) => Map<String, dynamic>.from(m)).toList();
        }
      } else if (dataVal is List) {
        rawEntries = dataVal.whereType<Map>()
            .map((m) => Map<String, dynamic>.from(m)).toList();
      }

      final entries = rawEntries.map(ShopEntry.fromJson).toList();

      // ── ALLE Cosmetic-Typen in eine Map laden ────────────
      // /v2/cosmetics gibt: { br: [...], tracks: [...], instruments: [...], lego: [...], ... }
      // Wir iterieren über ALLE Arrays, damit sid_XXX, CID_XXX, EID_XXX etc. alle abgedeckt sind.
      final cosmeticImages = <String, CosmeticImages>{};

      if (cosmeticsRes.statusCode == 200) {
        try {
          final cosJson = jsonDecode(cosmeticsRes.body) as Map<String, dynamic>;
          final cosData = cosJson['data'];

          Iterable<dynamic> allItems;
          if (cosData is List) {
            // Flache Liste
            allItems = cosData;
          } else if (cosData is Map) {
            // Alle Arrays zusammenfassen: br, tracks, instruments, lego, cars, beans, sparks, …
            allItems = cosData.values.expand((v) => v is List ? v : <dynamic>[]);
          } else {
            allItems = <dynamic>[];
          }

          for (final raw in allItems) {
            if (raw is Map) {
              final id = raw['id'] as String?;
              if (id != null && id.isNotEmpty) {
                cosmeticImages[id] = CosmeticImages.fromJson(
                    Map<String, dynamic>.from(raw));
              }
            }
          }
        } catch (_) {
          // nicht kritisch
        }
      }

      _data = ShopData(
        entries:        entries,
        cosmeticImages: cosmeticImages,
        fetchedAt:      DateTime.now(),
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
