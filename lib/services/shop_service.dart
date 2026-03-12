import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// ─────────────────────────────────────────────────────────
// Datenmodelle
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

  String? get displayImage {
    if (items.isEmpty) return null;
    return items.first.featuredImage ?? items.first.iconImage;
  }

  ShopItem? get primaryItem => items.isNotEmpty ? items.first : null;

  factory ShopEntry.fromJson(Map<String, dynamic> j) {
    // Bundle-Name
    String? bundleName;
    final bundle = j['bundle'];
    if (bundle is Map) {
      bundleName = bundle['name'] as String?;
    }

    // Section-Name – API liefert manchmal String, manchmal Map
    String sectionName = 'Shop';
    final section = j['section'];
    if (section is Map) {
      sectionName = (section['name'] as String?) ?? 'Shop';
    } else if (section is String) {
      sectionName = section;
    }
    // Fallback: categories Liste
    if (sectionName == 'Shop') {
      final cats = j['categories'];
      if (cats is List && cats.isNotEmpty) {
        sectionName = cats.first.toString();
      }
    }

    // Items
    final rawItems = j['items'];
    final List<ShopItem> items;
    if (rawItems is List) {
      items = rawItems
          .whereType<Map>()
          .map((m) => ShopItem.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    } else {
      items = [];
    }

    return ShopEntry(
      finalPrice: _toInt(j['finalPrice']) ?? _toInt(j['price']) ?? 0,
      regularPrice: _toInt(j['regularPrice']) ?? _toInt(j['finalPrice']) ?? _toInt(j['price']) ?? 0,
      bundleName: bundleName,
      sectionName: sectionName,
      items: items,
    );
  }
}

class ShopItem {
  final String id;
  final String name;
  final String description;
  final String typeDisplay;
  final String rarityValue;
  final String rarityDisplay;
  final String? iconImage;
  final String? featuredImage;

  const ShopItem({
    required this.id,
    required this.name,
    required this.description,
    required this.typeDisplay,
    required this.rarityValue,
    required this.rarityDisplay,
    this.iconImage,
    this.featuredImage,
  });

  factory ShopItem.fromJson(Map<String, dynamic> j) {
    // type: kann Map oder String sein
    String typeDisplay = '';
    final type = j['type'];
    if (type is Map) {
      typeDisplay = (type['displayValue'] as String?) ?? (type['value'] as String?) ?? '';
    } else if (type is String) {
      typeDisplay = type;
    }

    // rarity: kann Map oder String sein
    String rarityValue = 'common';
    String rarityDisplay = '';
    final rarity = j['rarity'];
    if (rarity is Map) {
      rarityValue = (rarity['value'] as String?) ?? 'common';
      rarityDisplay = (rarity['displayValue'] as String?) ?? '';
    } else if (rarity is String) {
      rarityValue = rarity;
    }

    // images
    String? iconImage;
    String? featuredImage;
    final images = j['images'];
    if (images is Map) {
      iconImage = images['icon'] as String?;
      featuredImage = images['featured'] as String?;
      // Fallback: smallIcon, background
      iconImage ??= images['smallIcon'] as String?;
      featuredImage ??= images['featuredSmall'] as String?;
    }

    return ShopItem(
      id: j['id'] as String? ?? '',
      name: j['name'] as String? ?? '???',
      description: j['description'] as String? ?? '',
      typeDisplay: typeDisplay,
      rarityValue: rarityValue,
      rarityDisplay: rarityDisplay,
      iconImage: iconImage,
      featuredImage: featuredImage,
    );
  }
}

class ShopData {
  final List<ShopEntry> entries;
  final DateTime fetchedAt;
  final String rawDebug; // für Fehleranalyse

  const ShopData({
    required this.entries,
    required this.fetchedAt,
    this.rawDebug = '',
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
// Hilfsfunktion
// ─────────────────────────────────────────────────────────
int? _toInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

// ─────────────────────────────────────────────────────────
// Service
// ─────────────────────────────────────────────────────────
class ShopService extends ChangeNotifier {
  static const _apiKey = '135f01ed-1a5e-40df-b8b6-4b2c97f47151';
  static const _url = 'https://fortnite-api.com/v2/shop';

  ShopData? _data;
  bool _loading = false;
  String? _error;
  String _debugInfo = '';
  Timer? _timer;

  ShopData? get data => _data;
  bool get loading => _loading;
  String? get error => _error;
  String get debugInfo => _debugInfo;

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
    final now = DateTime.now();
    final nextHour = DateTime(now.year, now.month, now.day, now.hour + 1);
    final delay = nextHour.difference(now);
    _timer = Timer(delay, () {
      fetch();
      _timer = Timer.periodic(const Duration(hours: 1), (_) => fetch());
    });
  }

  Future<void> fetch() async {
    if (_loading) return;
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await http.get(
        Uri.parse(_url),
        headers: {
          'Authorization': _apiKey,
          'Accept': 'application/json',
          'User-Agent': 'Orbit/1.0',
        },
      ).timeout(const Duration(seconds: 20));

      if (res.statusCode != 200) {
        throw Exception('HTTP ${res.statusCode}: ${res.body.substring(0, res.body.length.clamp(0, 200))}');
      }

      final decoded = jsonDecode(res.body);
      final json = decoded as Map<String, dynamic>;

      // Top-Level-Keys für Debug speichern
      final topKeys = json.keys.toList();
      final dataVal = json['data'];
      String debugStr = 'Top: $topKeys';

      List<Map<String, dynamic>> rawEntries = [];

      if (dataVal is Map) {
        final shopMap = Map<String, dynamic>.from(dataVal);
        debugStr += ' | data keys: ${shopMap.keys.toList()}';

        // Variante 1: data.entries (neue API)
        final entriesRaw = shopMap['entries'];
        if (entriesRaw is List && entriesRaw.isNotEmpty) {
          rawEntries = entriesRaw.whereType<Map>()
              .map((m) => Map<String, dynamic>.from(m))
              .toList();
          debugStr += ' | entries: ${rawEntries.length}';
        }

        // Variante 2: data.featured + data.daily (alte API)
        if (rawEntries.isEmpty) {
          final featured = shopMap['featured'];
          final daily = shopMap['daily'];
          if (featured is Map) {
            final fe = featured['entries'];
            if (fe is List) {
              rawEntries.addAll(fe.whereType<Map>().map((m) => Map<String, dynamic>.from(m)));
            }
          }
          if (daily is Map) {
            final de = daily['entries'];
            if (de is List) {
              rawEntries.addAll(de.whereType<Map>().map((m) => Map<String, dynamic>.from(m)));
            }
          }
          debugStr += ' | featured+daily: ${rawEntries.length}';
        }

        // Variante 3: data direkt ist eine Liste
        if (rawEntries.isEmpty && dataVal is List) {
          rawEntries = (dataVal as List).whereType<Map>()
              .map((m) => Map<String, dynamic>.from(m))
              .toList();
          debugStr += ' | data-as-list: ${rawEntries.length}';
        }
      } else if (dataVal is List) {
        // data selbst ist die Liste
        rawEntries = dataVal.whereType<Map>()
            .map((m) => Map<String, dynamic>.from(m))
            .toList();
        debugStr += ' | data-list: ${rawEntries.length}';
      }

      // Debug: erste Entry-Keys anzeigen
      if (rawEntries.isNotEmpty) {
        debugStr += ' | entry[0] keys: ${rawEntries.first.keys.toList()}';
      }

      _debugInfo = debugStr;

      final entries = rawEntries.map(ShopEntry.fromJson).toList();

      _data = ShopData(
        entries: entries,
        fetchedAt: DateTime.now(),
        rawDebug: debugStr,
      );
    } catch (e) {
      _error = e.toString();
      _debugInfo = 'Error: $_error';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
