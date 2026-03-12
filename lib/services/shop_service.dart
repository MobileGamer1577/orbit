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

  bool get isBundle => bundleName != null;

  /// Anzeigename: Bundle-Name oder erster Item-Name
  String get displayName =>
      bundleName ?? (items.isNotEmpty ? items.first.name : '???');

  /// Bild: Featured-Bild bevorzugt, dann Icon
  String? get displayImage {
    if (items.isEmpty) return null;
    final item = items.first;
    return item.featuredImage ?? item.iconImage;
  }

  ShopItem? get primaryItem => items.isNotEmpty ? items.first : null;

  factory ShopEntry.fromJson(Map<String, dynamic> j) {
    final bundleData = j['bundle'] as Map<String, dynamic>?;
    final sectionData = j['section'] as Map<String, dynamic>?;
    final rawItems = (j['items'] as List?) ?? [];

    return ShopEntry(
      finalPrice: (j['finalPrice'] as num?)?.toInt() ?? 0,
      regularPrice: (j['regularPrice'] as num?)?.toInt() ?? 0,
      bundleName: bundleData?['name'] as String?,
      sectionName: sectionData?['name'] as String? ?? 'Featured',
      items: rawItems
          .cast<Map<String, dynamic>>()
          .map(ShopItem.fromJson)
          .toList(),
    );
  }
}

class ShopItem {
  final String id;
  final String name;
  final String description;
  final String typeDisplay;
  final String rarityValue;   // common, uncommon, rare, epic, legendary, …
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
    final type = j['type'] as Map<String, dynamic>?;
    final rarity = j['rarity'] as Map<String, dynamic>?;
    final images = j['images'] as Map<String, dynamic>?;

    return ShopItem(
      id: j['id'] as String? ?? '',
      name: j['name'] as String? ?? '???',
      description: j['description'] as String? ?? '',
      typeDisplay: type?['displayValue'] as String? ?? '',
      rarityValue: rarity?['value'] as String? ?? 'common',
      rarityDisplay: rarity?['displayValue'] as String? ?? '',
      iconImage: images?['icon'] as String?,
      featuredImage: images?['featured'] as String?,
    );
  }
}

class ShopData {
  final List<ShopEntry> entries;
  final DateTime fetchedAt;

  const ShopData({required this.entries, required this.fetchedAt});

  /// Gruppiert nach Section-Name
  Map<String, List<ShopEntry>> get bySection {
    final map = <String, List<ShopEntry>>{};
    for (final e in entries) {
      map.putIfAbsent(e.sectionName, () => []).add(e);
    }
    return map;
  }
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
  Timer? _timer;

  ShopData? get data => _data;
  bool get loading => _loading;
  String? get error => _error;

  ShopService() {
    fetch();
    _scheduleHourlyRefresh();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ── Stündliche Aktualisierung zur vollen Stunde ──────────
  void _scheduleHourlyRefresh() {
    _timer?.cancel();
    final now = DateTime.now();
    // Sekunden bis zur nächsten vollen Stunde
    final nextHour = DateTime(now.year, now.month, now.day, now.hour + 1);
    final delay = nextHour.difference(now);

    _timer = Timer(delay, () {
      fetch();
      // Danach jede volle Stunde
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
        },
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode != 200) {
        throw Exception('HTTP ${res.statusCode}');
      }

      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final shopData = json['data'] as Map<String, dynamic>;
      final rawEntries = (shopData['entries'] as List?) ?? [];

      final entries = rawEntries
          .cast<Map<String, dynamic>>()
          .map(ShopEntry.fromJson)
          .where((e) => e.items.isNotEmpty)
          .toList();

      _data = ShopData(entries: entries, fetchedAt: DateTime.now());
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
