import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_keys.dart';

class ShopEntry {
  final int finalPrice;
  final int regularPrice;
  final String? bundleName;
  final String sectionName;
  final String devName;
  final String displayName;
  final String? imageUrl;
  final String rarityValue;
  final String typeDisplay;
  // Filter & Sort
  final String typeValue;
  final bool hasTracks;
  final String seriesValue;
  final int sortPriority;
  final DateTime? inDate;

  const ShopEntry({
    required this.finalPrice,
    required this.regularPrice,
    this.bundleName,
    required this.sectionName,
    required this.devName,
    required this.displayName,
    this.imageUrl,
    required this.rarityValue,
    required this.typeDisplay,
    required this.typeValue,
    required this.hasTracks,
    required this.seriesValue,
    required this.sortPriority,
    this.inDate,
  });

  bool get isBundle => bundleName != null && bundleName!.isNotEmpty;
  bool get isOnSale => finalPrice < regularPrice;

  factory ShopEntry.fromJson(Map<String, dynamic> j) {
    String sectionName = 'Shop';
    final layout = j['layout'];
    if (layout is Map) {
      final n = layout['name'] as String?;
      if (n != null && n.isNotEmpty) sectionName = n;
    }

    String? bundleName;
    final bundle = j['bundle'];
    if (bundle is Map) bundleName = bundle['name'] as String?;

    final rawBr = j['brItems'];
    final brItems = rawBr is List ? rawBr.whereType<Map>().toList() : <Map>[];

    final rawTracks = j['tracks'];
    final tracks = rawTracks is List
        ? rawTracks.whereType<Map>().toList()
        : <Map>[];

    String displayName = '';
    if (bundleName != null && bundleName.isNotEmpty) {
      displayName = bundleName;
    } else if (brItems.isNotEmpty) {
      displayName = (brItems.first['name'] as String?) ?? '';
    } else if (tracks.isNotEmpty) {
      final t = tracks.first;
      final title = (t['title'] as String?) ?? '';
      final artist = (t['artist'] as String?) ?? '';
      displayName = artist.isNotEmpty ? '$title \u2013 $artist' : title;
    }
    if (displayName.isEmpty) {
      final dev = (j['devName'] as String?) ?? '';
      final match = RegExp(
        r'\[VIRTUAL\]\d+\s*x\s*(.+?)\s+for\s+\d+',
        caseSensitive: false,
      ).firstMatch(dev);
      displayName = match != null ? match.group(1)! : dev;
    }

    String? imageUrl;
    final nda = j['newDisplayAsset'];
    if (nda is Map) {
      final renders = nda['renderImages'];
      if (renders is List && renders.isNotEmpty) {
        final first = renders.first;
        if (first is Map) imageUrl = first['image'] as String?;
      }
    }
    if (imageUrl == null && brItems.isNotEmpty) {
      final imgs = brItems.first['images'];
      if (imgs is Map) {
        imageUrl =
            (imgs['featured'] as String?) ??
            (imgs['icon'] as String?) ??
            (imgs['smallIcon'] as String?);
      }
    }
    if (imageUrl == null && tracks.isNotEmpty) {
      imageUrl = tracks.first['albumArt'] as String?;
    }

    String rarityValue = 'common';
    String typeDisplay = '';
    String typeValue = '';
    if (brItems.isNotEmpty) {
      final rarity = brItems.first['rarity'];
      if (rarity is Map) rarityValue = (rarity['value'] as String?) ?? 'common';
      final type = brItems.first['type'];
      if (type is Map) {
        typeDisplay =
            (type['displayValue'] as String?) ??
            (type['value'] as String?) ??
            '';
        typeValue = (type['value'] as String?) ?? '';
      }
    }

    String seriesValue = '';
    if (brItems.isNotEmpty) {
      final series = brItems.first['series'];
      if (series is Map) {
        seriesValue = (series['value'] as String?) ?? '';
      } else {
        final set_ = brItems.first['set'];
        if (set_ is Map) seriesValue = (set_['value'] as String?) ?? '';
      }
    }

    final sortPriority = (j['sortPriority'] as int?) ?? 0;
    DateTime? inDate;
    final inDateStr = j['inDate'] as String?;
    if (inDateStr != null) inDate = DateTime.tryParse(inDateStr);

    return ShopEntry(
      finalPrice: _toInt(j['finalPrice']) ?? _toInt(j['price']) ?? 0,
      regularPrice:
          _toInt(j['regularPrice']) ??
          _toInt(j['finalPrice']) ??
          _toInt(j['price']) ??
          0,
      bundleName: bundleName,
      sectionName: sectionName,
      devName: (j['devName'] as String?) ?? '',
      displayName: displayName,
      imageUrl: imageUrl,
      rarityValue: rarityValue,
      typeDisplay: typeDisplay,
      typeValue: typeValue,
      hasTracks: tracks.isNotEmpty,
      seriesValue: seriesValue,
      sortPriority: sortPriority,
      inDate: inDate,
    );
  }
}

int? _toInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

class ShopData {
  final List<ShopEntry> entries;
  final DateTime fetchedAt;
  const ShopData({required this.entries, required this.fetchedAt});

  Map<String, List<ShopEntry>> get bySection {
    final map = <String, List<ShopEntry>>{};
    for (final e in entries) {
      map.putIfAbsent(e.sectionName, () => []).add(e);
    }
    return map;
  }
}

class ShopService extends ChangeNotifier {
  static const _shopUrl = 'https://fortnite-api.com/v2/shop';
  static const Map<String, String> _headers = {
    'Authorization': ApiKeys.fortniteApiCom,
    'Accept': 'application/json',
    'User-Agent': 'Orbit/1.0',
  };

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

  void _scheduleHourlyRefresh() {
    _timer?.cancel();
    final now = DateTime.now();
    final nextHour = DateTime(now.year, now.month, now.day, now.hour + 1);
    _timer = Timer(nextHour.difference(now), () {
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
      final res = await http
          .get(Uri.parse(_shopUrl), headers: _headers)
          .timeout(const Duration(seconds: 20));
      if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
      final shopJson = jsonDecode(res.body) as Map<String, dynamic>;
      final dataVal = shopJson['data'];
      List<dynamic> rawEntries = [];
      if (dataVal is Map) {
        final e = dataVal['entries'];
        if (e is List) rawEntries = e;
      } else if (dataVal is List) {
        rawEntries = dataVal;
      }
      final entries = rawEntries
          .whereType<Map>()
          .map((m) => ShopEntry.fromJson(Map<String, dynamic>.from(m)))
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
