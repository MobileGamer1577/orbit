import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

// ══════════════════════════════════════════════════════════════
//
//  🔄 OPSUCHT SYNC SERVICE
//  Datei: lib/services/opsucht_sync_service.dart
//
//  Lädt OPPASS-Bilder, Season-Daten und Items aus GitHub.
//  Alle Daten werden lokal gecacht → Offline-Nutzung möglich.
//
//  GitHub-Quellen:
//    Season/OPPASS: [dein Repo] (konfigurierbar)
//    Items:         github.com/geldbedarf/OPMOD_REPO
//
//  Cache-Ordner im App-Dokumente-Verzeichnis:
//    opsucht/oppass/     → Bilder (1.png–20.png)
//    opsucht/items/      → Item-JSON-Dateien
//    opsucht/config/     → season.json
//
// ══════════════════════════════════════════════════════════════

// ── Konfiguration ──────────────────────────────────────────────
//
//  ✏️  Hier deine GitHub-Repo-URL eintragen sobald verfügbar.
//      Raw-URL Format: https://raw.githubusercontent.com/USER/REPO/BRANCH/
//
const String _kOppassRawBase =
    'https://raw.githubusercontent.com/MobileGamer1577/orbit/main/opsucht/oppass/';
const String _kConfigRawBase =
    'https://raw.githubusercontent.com/MobileGamer1577/orbit/main/opsucht/config/';
const String _kItemsRawBase =
    'https://raw.githubusercontent.com/geldbedarf/OPMOD_REPO/main/items/';
const String _kItemsApiBase =
    'https://api.github.com/repos/geldbedarf/OPMOD_REPO/contents/items';

const Duration _kCacheTtl = Duration(hours: 6);
const Duration _kTimeout  = Duration(seconds: 20);

// ──────────────────────────────────────────────────────────────
//  Datenmodelle
// ──────────────────────────────────────────────────────────────

class OpSuchtSeasonData {
  final String name;           // z.B. "Redstone"
  final DateTime seasonEnd;
  final DateTime seasonStart;
  final int totalImages;       // wie viele Bilder (1.png–N.png)

  const OpSuchtSeasonData({
    required this.name,
    required this.seasonEnd,
    required this.seasonStart,
    required this.totalImages,
  });

  factory OpSuchtSeasonData.fromJson(Map<String, dynamic> j) {
    return OpSuchtSeasonData(
      name:        (j['name']         as String?) ?? 'Season',
      seasonEnd:   DateTime.parse((j['season_end']   as String)),
      seasonStart: DateTime.parse((j['season_start'] as String)),
      totalImages: (j['total_images'] as int?) ?? 20,
    );
  }

  /// Fallback wenn kein season.json vorhanden
  factory OpSuchtSeasonData.fallback() => OpSuchtSeasonData(
    name:        'Season',
    seasonEnd:   DateTime.now().add(const Duration(days: 30)),
    seasonStart: DateTime.now().subtract(const Duration(days: 30)),
    totalImages: 20,
  );

  Duration get timeRemaining => seasonEnd.difference(DateTime.now());
  bool get isEndingSoon      => timeRemaining.inDays < 2;
  bool get isEndingVeryLoon  => timeRemaining.inHours < 24;
}

class OpSuchtItem {
  final String internalname;
  final String displayname;
  final String material;
  final int    cmd;
  final String lore;
  final String nbttag;
  final String alternativeRaritys;
  final String shardPrice;
  final String capturedAt;

  const OpSuchtItem({
    required this.internalname,
    required this.displayname,
    required this.material,
    required this.cmd,
    required this.lore,
    required this.nbttag,
    required this.alternativeRaritys,
    required this.shardPrice,
    required this.capturedAt,
  });

  factory OpSuchtItem.fromJson(Map<String, dynamic> j) => OpSuchtItem(
    internalname:       (j['internalname']        as String?) ?? '',
    displayname:        (j['displayname']          as String?) ?? '',
    material:           (j['material']             as String?) ?? '',
    cmd:                (j['cmd']                  as int?)    ?? 0,
    lore:               (j['lore']                 as String?) ?? '',
    nbttag:             (j['nbttag']               as String?) ?? '',
    alternativeRaritys: (j['alternative_raritys']  as String?) ?? '',
    shardPrice:         (j['shard_price']           as String?) ?? '',
    capturedAt:         (j['capturedAt']            as String?) ?? '',
  );
}

// ──────────────────────────────────────────────────────────────
//  Sync Service (Singleton)
// ──────────────────────────────────────────────────────────────

class OpSuchtSyncService extends ChangeNotifier {
  static final OpSuchtSyncService instance = OpSuchtSyncService._();
  OpSuchtSyncService._();

  // ── State ─────────────────────────────────────────────────

  bool _seasonLoaded   = false;
  bool _itemsLoaded    = false;
  bool _syncing        = false;
  String? _error;

  OpSuchtSeasonData? _season;
  List<OpSuchtItem> _items = [];
  List<String>      _cachedImagePaths = [];   // lokale Pfade der OPPASS-Bilder

  bool get seasonLoaded => _seasonLoaded;
  bool get itemsLoaded  => _itemsLoaded;
  bool get syncing      => _syncing;
  String? get error     => _error;

  OpSuchtSeasonData get season => _season ?? OpSuchtSeasonData.fallback();
  List<OpSuchtItem> get items  => _items;
  List<String> get oppassImages => _cachedImagePaths;

  // ── Cache-Verzeichnisse ────────────────────────────────────

  Future<Directory> get _oppassDir async {
    final base = await getApplicationDocumentsDirectory();
    final dir  = Directory('${base.path}/opsucht/oppass');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<Directory> get _itemsDir async {
    final base = await getApplicationDocumentsDirectory();
    final dir  = Directory('${base.path}/opsucht/items');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<Directory> get _configDir async {
    final base = await getApplicationDocumentsDirectory();
    final dir  = Directory('${base.path}/opsucht/config');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  // ── Timestamp-Dateien (Cache-TTL) ─────────────────────────

  Future<bool> _isCacheValid(String key) async {
    try {
      final dir  = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/opsucht/.ts_$key');
      if (!await file.exists()) return false;
      final ts  = int.tryParse(await file.readAsString()) ?? 0;
      final age = DateTime.now().millisecondsSinceEpoch - ts;
      return age < _kCacheTtl.inMilliseconds;
    } catch (_) {
      return false;
    }
  }

  Future<void> _setTimestamp(String key) async {
    try {
      final dir  = await getApplicationDocumentsDirectory();
      await Directory('${dir.path}/opsucht').create(recursive: true);
      final file = File('${dir.path}/opsucht/.ts_$key');
      await file.writeAsString(
          DateTime.now().millisecondsSinceEpoch.toString());
    } catch (_) {}
  }

  // ══════════════════════════════════════════════════════════
  //  SEASON LADEN
  // ══════════════════════════════════════════════════════════

  Future<void> loadSeason({bool force = false}) async {
    // 1. Erst gecachte Daten anzeigen
    await _loadSeasonFromCache();

    // 2. Wenn Cache gültig und kein Force → fertig
    if (!force && await _isCacheValid('season')) {
      _seasonLoaded = true;
      notifyListeners();
      await _loadOppassImages();
      return;
    }

    // 3. Von GitHub laden
    await _syncSeason();
    await _syncOppassImages();
  }

  Future<void> _loadSeasonFromCache() async {
    try {
      final dir  = await _configDir;
      final file = File('${dir.path}/season.json');
      if (await file.exists()) {
        final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        _season = OpSuchtSeasonData.fromJson(json);
      }
    } catch (_) {}
  }

  Future<void> _syncSeason() async {
    try {
      final res = await http
          .get(Uri.parse('${_kConfigRawBase}season.json'),
               headers: {'User-Agent': 'Orbit-App'})
          .timeout(_kTimeout);

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        _season = OpSuchtSeasonData.fromJson(json);

        // In Cache schreiben
        final dir  = await _configDir;
        await File('${dir.path}/season.json').writeAsString(res.body);
        await _setTimestamp('season');
      }
    } catch (_) {
      // Kein season.json → Fallback nutzen
      _season ??= OpSuchtSeasonData.fallback();
    }
    _seasonLoaded = true;
    notifyListeners();
  }

  // ══════════════════════════════════════════════════════════
  //  OPPASS BILDER
  // ══════════════════════════════════════════════════════════

  Future<void> _loadOppassImages() async {
    final dir   = await _oppassDir;
    final total = _season?.totalImages ?? 20;
    final paths = <String>[];

    for (int i = 1; i <= total; i++) {
      final file = File('${dir.path}/$i.png');
      if (await file.exists()) paths.add(file.path);
    }

    _cachedImagePaths = paths;
    notifyListeners();
  }

  Future<void> _syncOppassImages() async {
    final dir   = await _oppassDir;
    final total = _season?.totalImages ?? 20;
    final paths = <String>[];

    for (int i = 1; i <= total; i++) {
      final file = File('${dir.path}/$i.png');

      // Nur herunterladen wenn noch nicht lokal vorhanden
      if (!await file.exists()) {
        try {
          final res = await http
              .get(Uri.parse('$_kOppassRawBase$i.png'),
                   headers: {'User-Agent': 'Orbit-App'})
              .timeout(_kTimeout);
          if (res.statusCode == 200) {
            await file.writeAsBytes(res.bodyBytes);
          }
        } catch (_) {
          // Bild nicht verfügbar → überspringen
          continue;
        }
      }

      if (await file.exists()) paths.add(file.path);
    }

    _cachedImagePaths = paths;
    notifyListeners();
  }

  // ══════════════════════════════════════════════════════════
  //  ITEMS LADEN
  // ══════════════════════════════════════════════════════════

  Future<void> loadItems({bool force = false}) async {
    // 1. Erst aus Cache
    await _loadItemsFromCache();
    if (_items.isNotEmpty) {
      _itemsLoaded = true;
      notifyListeners();
    }

    // 2. Cache prüfen
    if (!force && await _isCacheValid('items') && _items.isNotEmpty) return;

    // 3. Von GitHub laden
    await _syncItems();
  }

  Future<void> _loadItemsFromCache() async {
    try {
      final dir   = await _itemsDir;
      final files = dir.listSync().whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .toList();

      final loaded = <OpSuchtItem>[];
      for (final file in files) {
        try {
          final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
          loaded.add(OpSuchtItem.fromJson(json));
        } catch (_) {}
      }
      _items = loaded;
    } catch (_) {}
  }

  Future<void> _syncItems() async {
    _syncing = true;
    _error   = null;
    notifyListeners();

    try {
      // GitHub API → Liste aller JSON-Dateien im items/ Ordner
      final res = await http
          .get(Uri.parse(_kItemsApiBase),
               headers: {
                 'User-Agent': 'Orbit-App',
                 'Accept':     'application/vnd.github+json',
               })
          .timeout(const Duration(seconds: 30));

      if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');

      final listing = jsonDecode(res.body) as List;
      final jsonFiles = listing
          .whereType<Map<String, dynamic>>()
          .where((f) => (f['name'] as String).endsWith('.json'))
          .toList();

      final dir    = await _itemsDir;
      final loaded = <OpSuchtItem>[];

      // Items herunterladen (parallel, max 10 gleichzeitig)
      const batchSize = 10;
      for (int start = 0; start < jsonFiles.length; start += batchSize) {
        final batch = jsonFiles.skip(start).take(batchSize);
        await Future.wait(batch.map((f) async {
          final name    = f['name'] as String;
          final rawUrl  = f['download_url'] as String? ??
              '$_kItemsRawBase$name';
          final cacheFile = File('${dir.path}/$name');

          try {
            final itemRes = await http
                .get(Uri.parse(rawUrl),
                     headers: {'User-Agent': 'Orbit-App'})
                .timeout(_kTimeout);
            if (itemRes.statusCode == 200) {
              await cacheFile.writeAsString(itemRes.body);
              final json =
                  jsonDecode(itemRes.body) as Map<String, dynamic>;
              loaded.add(OpSuchtItem.fromJson(json));
            }
          } catch (_) {
            // Lokale Kopie nutzen falls vorhanden
            if (await cacheFile.exists()) {
              try {
                final json = jsonDecode(await cacheFile.readAsString())
                    as Map<String, dynamic>;
                loaded.add(OpSuchtItem.fromJson(json));
              } catch (_) {}
            }
          }
        }));
      }

      _items = loaded;
      await _setTimestamp('items');

    } catch (e) {
      _error = e.toString();
      // Falls Cache vorhanden, nutzen
      if (_items.isEmpty) await _loadItemsFromCache();
    } finally {
      _syncing      = false;
      _itemsLoaded  = true;
      notifyListeners();
    }
  }

  // ── Manueller Refresh ─────────────────────────────────────

  Future<void> forceRefreshAll() async {
    await loadSeason(force: true);
    await loadItems(force: true);
  }
}
