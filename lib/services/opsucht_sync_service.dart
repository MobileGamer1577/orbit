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
//    Season/OPPASS/Items: MobileGamer1577/orbit (lib/opsucht/)
//    Items-Fallback:      github.com/geldbedarf/OPMOD_REPO
//
//  Korrekte Raw-URL-Basis (Dateien liegen unter lib/opsucht/):
//    https://raw.githubusercontent.com/MobileGamer1577/orbit/main/lib/opsucht/
//
//  Cache-Ordner im App-Dokumente-Verzeichnis:
//    opsucht/oppass/     → Bilder (1.png–20.png)
//    opsucht/items/      → Item-JSON-Dateien
//    opsucht/config/     → season.json
//
//  ✏️  URL ANPASSEN:
//    Falls du die Dateien in einen anderen Ordner/Repo verschiebst,
//    passe _kRepoRawBase unten an. Alle anderen Pfade werden
//    automatisch daraus abgeleitet.
//
// ══════════════════════════════════════════════════════════════

// ── Konfiguration ──────────────────────────────────────────────
//
//  ⚠️  WICHTIG: GitHub Raw-URLs brauchen immer das Format:
//      https://raw.githubusercontent.com/USER/REPO/BRANCH/PFAD
//      NICHT: https://github.com/USER/REPO/blob/BRANCH/PFAD
//      (blob-Links sind Browser-Links, keine direkten Datei-Links)
//
//  Die Dateien liegen im Orbit-Repo unter lib/opsucht/:
//    lib/opsucht/oppass/1.png ... 20.png
//    lib/opsucht/config/season.json
//    lib/opsucht/items/*.json
//
const String _kRepoRawBase =
    'https://raw.githubusercontent.com/MobileGamer1577/orbit/main/lib/opsucht/';

// Abgeleitete Pfade — bei Bedarf einzeln überschreiben
const String _kOppassRawBase = _kRepoRawBase + 'oppass/';
const String _kConfigRawBase = _kRepoRawBase + 'config/';
const String _kItemsRawBase  = _kRepoRawBase + 'items/';

// GitHub API für Items-Listing
const String _kItemsApiBase =
    'https://api.github.com/repos/MobileGamer1577/orbit/contents/lib/opsucht/items';

// Fallback: externer OPMOD_REPO
const String _kItemsFallbackApiBase =
    'https://api.github.com/repos/geldbedarf/OPMOD_REPO/contents/items';
const String _kItemsFallbackRawBase =
    'https://raw.githubusercontent.com/geldbedarf/OPMOD_REPO/main/items/';

const Duration _kCacheTtl = Duration(hours: 6);
const Duration _kTimeout  = Duration(seconds: 20);

// ──────────────────────────────────────────────────────────────
//  Datenmodelle
// ──────────────────────────────────────────────────────────────

class OpSuchtSeasonData {
  final String name;
  final DateTime seasonEnd;
  final DateTime seasonStart;
  final int totalImages;

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

// ──────────────────────────────────────────────────────────────
//  OpSuchtItem — robuster Parser
//
//  Unterstützt:
//    • lore als String ODER List<dynamic>
//    • fehlende Felder → leerer String / 0
//    • zusätzliche Felder → werden ignoriert
//    • null-sicher für alle Felder
// ──────────────────────────────────────────────────────────────

class OpSuchtItem {
  final String internalname;
  final String displayname;
  final String material;
  final int    cmd;
  final int    damage;
  final String lore;           // immer String (Zeilen mit \n getrennt)
  final String nbttag;
  final String alternativeRaritys;
  final String shardPrice;
  final String capturedAt;

  const OpSuchtItem({
    required this.internalname,
    required this.displayname,
    required this.material,
    required this.cmd,
    required this.damage,
    required this.lore,
    required this.nbttag,
    required this.alternativeRaritys,
    required this.shardPrice,
    required this.capturedAt,
  });

  factory OpSuchtItem.fromJson(Map<String, dynamic> j) {
    // lore: String oder Array → immer String
    String parseLore(dynamic raw) {
      if (raw == null) return '';
      if (raw is String) return raw;
      if (raw is List) {
        return raw
            .map((e) => e?.toString() ?? '')
            .join('\n')
            .trim();
      }
      return raw.toString();
    }

    // int-Felder robust parsen
    int parseInt(dynamic raw) {
      if (raw == null) return 0;
      if (raw is int) return raw;
      if (raw is double) return raw.toInt();
      return int.tryParse(raw.toString()) ?? 0;
    }

    String str(dynamic raw) => raw?.toString() ?? '';

    return OpSuchtItem(
      internalname:       str(j['internalname']),
      displayname:        str(j['displayname']),
      material:           str(j['material']),
      cmd:                parseInt(j['cmd']),
      damage:             parseInt(j['damage']),
      lore:               parseLore(j['lore']),
      nbttag:             str(j['nbttag']),
      alternativeRaritys: str(j['alternative_raritys']),
      shardPrice:         str(j['shard_price']),
      capturedAt:         str(j['capturedAt']),
    );
  }

  /// Suchindex — alle durchsuchbaren Felder
  String get searchIndex =>
      '$displayname $internalname $material'.toLowerCase();
}

// ──────────────────────────────────────────────────────────────
//  Sync Service (Singleton)
// ──────────────────────────────────────────────────────────────

class OpSuchtSyncService extends ChangeNotifier {
  static final OpSuchtSyncService instance = OpSuchtSyncService._();
  OpSuchtSyncService._();

  bool _seasonLoaded   = false;
  bool _itemsLoaded    = false;
  bool _syncing        = false;
  String? _error;

  OpSuchtSeasonData? _season;
  List<OpSuchtItem> _items = [];
  List<String>      _cachedImagePaths = [];

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
    await _loadSeasonFromCache();

    if (!force && await _isCacheValid('season')) {
      _seasonLoaded = true;
      notifyListeners();
      await _loadOppassImages();
      return;
    }

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
      // ✅ Korrekte Raw-URL: lib/opsucht/config/season.json
      final url = '${_kConfigRawBase}season.json';
      debugPrint('[OpSucht] Lade season.json: $url');

      final res = await http
          .get(Uri.parse(url),
               headers: {
                 'User-Agent': 'Orbit-App',
                 'Cache-Control': 'no-cache',
               })
          .timeout(_kTimeout);

      debugPrint('[OpSucht] season.json HTTP ${res.statusCode}');

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        _season = OpSuchtSeasonData.fromJson(json);

        final dir  = await _configDir;
        await File('${dir.path}/season.json').writeAsString(res.body);
        await _setTimestamp('season');
        debugPrint('[OpSucht] Season geladen: ${_season?.name}');
      }
    } catch (e) {
      debugPrint('[OpSucht] season.json Fehler: $e');
    }

    _season ??= OpSuchtSeasonData.fallback();
    _seasonLoaded = true;
    notifyListeners();
  }

  // ══════════════════════════════════════════════════════════
  //  OPPASS BILDER
  //
  //  Bilder liegen unter: lib/opsucht/oppass/1.png ... N.png
  //  Raw-URL: _kOppassRawBase + "1.png"
  //         = https://raw.githubusercontent.com/.../lib/opsucht/oppass/1.png
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
    debugPrint('[OpSucht] ${paths.length} gecachte Bilder geladen');
    notifyListeners();
  }

  Future<void> _syncOppassImages() async {
    final dir   = await _oppassDir;
    final total = _season?.totalImages ?? 20;
    final paths = <String>[];

    for (int i = 1; i <= total; i++) {
      final file = File('${dir.path}/$i.png');

      if (!await file.exists()) {
        // ✅ Korrekte Raw-URL: lib/opsucht/oppass/1.png
        final url = '$_kOppassRawBase$i.png';
        debugPrint('[OpSucht] Lade Bild $i: $url');

        try {
          final res = await http
              .get(Uri.parse(url),
                   headers: {
                     'User-Agent': 'Orbit-App',
                     'Cache-Control': 'no-cache',
                   })
              .timeout(_kTimeout);

          debugPrint('[OpSucht] Bild $i → HTTP ${res.statusCode} (${res.bodyBytes.length} bytes)');

          if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
            await file.writeAsBytes(res.bodyBytes);
          } else {
            continue;
          }
        } catch (e) {
          debugPrint('[OpSucht] Bild $i Fehler: $e');
          continue;
        }
      }

      if (await file.exists()) paths.add(file.path);
    }

    _cachedImagePaths = paths;
    debugPrint('[OpSucht] ${paths.length} Bilder gesamt verfügbar');
    notifyListeners();
  }

  // ══════════════════════════════════════════════════════════
  //  ITEMS LADEN
  //
  //  Primär:  lib/opsucht/items/ im Orbit-Repo
  //  Fallback: geldbedarf/OPMOD_REPO
  // ══════════════════════════════════════════════════════════

  Future<void> loadItems({bool force = false}) async {
    await _loadItemsFromCache();
    if (_items.isNotEmpty) {
      _itemsLoaded = true;
      notifyListeners();
    }

    if (!force && await _isCacheValid('items') && _items.isNotEmpty) return;

    await _syncItems();
  }

  Future<void> _loadItemsFromCache() async {
    try {
      final dir = await _itemsDir;
      if (!await dir.exists()) return;

      final files = dir.listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .toList();

      final loaded = <OpSuchtItem>[];
      for (final file in files) {
        try {
          final json = jsonDecode(await file.readAsString());
          if (json is Map<String, dynamic>) {
            final item = OpSuchtItem.fromJson(json);
            if (item.internalname.isNotEmpty || item.displayname.isNotEmpty) {
              loaded.add(item);
            }
          }
        } catch (e) {
          debugPrint('[OpSucht] Cache-Lesefehler ${file.path}: $e');
        }
      }

      loaded.sort((a, b) {
        final nameA = a.displayname.isNotEmpty ? a.displayname : a.internalname;
        final nameB = b.displayname.isNotEmpty ? b.displayname : b.internalname;
        return nameA.toLowerCase().compareTo(nameB.toLowerCase());
      });

      _items = loaded;
      debugPrint('[OpSucht] ${_items.length} Items aus Cache');
    } catch (e) {
      debugPrint('[OpSucht] Item-Cache Fehler: $e');
    }
  }

  Future<void> _syncItems() async {
    _syncing = true;
    _error   = null;
    notifyListeners();

    bool success = await _syncItemsFromRepo(
      apiUrl:  _kItemsApiBase,
      rawBase: _kItemsRawBase,
      label:   'Orbit-Repo',
    );

    if (!success) {
      debugPrint('[OpSucht] Orbit-Repo leer → Fallback zu OPMOD_REPO');
      success = await _syncItemsFromRepo(
        apiUrl:  _kItemsFallbackApiBase,
        rawBase: _kItemsFallbackRawBase,
        label:   'OPMOD_REPO',
      );
    }

    _syncing     = false;
    _itemsLoaded = true;

    if (!success && _items.isEmpty) {
      _error = 'Keine Items gefunden. Prüfe deine Internetverbindung.';
    }

    notifyListeners();
  }

  Future<bool> _syncItemsFromRepo({
    required String apiUrl,
    required String rawBase,
    required String label,
  }) async {
    try {
      debugPrint('[OpSucht] Items von $label: $apiUrl');

      final res = await http
          .get(Uri.parse(apiUrl),
               headers: {
                 'User-Agent': 'Orbit-App',
                 'Accept':     'application/vnd.github+json',
                 'Cache-Control': 'no-cache',
               })
          .timeout(const Duration(seconds: 30));

      debugPrint('[OpSucht] $label API → HTTP ${res.statusCode}');

      if (res.statusCode != 200) return false;

      final listing = jsonDecode(res.body);
      if (listing is! List) return false;

      final jsonFiles = listing
          .whereType<Map<String, dynamic>>()
          .where((f) {
            final name = (f['name'] as String?) ?? '';
            final type = (f['type'] as String?) ?? '';
            return name.endsWith('.json') && type == 'file';
          })
          .toList();

      debugPrint('[OpSucht] $label: ${jsonFiles.length} JSON-Dateien');
      if (jsonFiles.isEmpty) return false;

      final dir    = await _itemsDir;
      final loaded = <OpSuchtItem>[];

      // Parallel laden, max 5 gleichzeitig
      const batchSize = 5;
      for (int start = 0; start < jsonFiles.length; start += batchSize) {
        final batch = jsonFiles.skip(start).take(batchSize).toList();

        await Future.wait(batch.map((f) async {
          final name = (f['name'] as String?) ?? '';
          if (name.isEmpty) return;

          final rawUrl    = (f['download_url'] as String?) ?? '$rawBase$name';
          final cacheFile = File('${dir.path}/$name');

          try {
            final itemRes = await http
                .get(Uri.parse(rawUrl),
                     headers: {
                       'User-Agent': 'Orbit-App',
                       'Cache-Control': 'no-cache',
                     })
                .timeout(_kTimeout);

            if (itemRes.statusCode == 200 && itemRes.body.isNotEmpty) {
              await cacheFile.writeAsString(itemRes.body);
              final json = jsonDecode(itemRes.body);
              if (json is Map<String, dynamic>) {
                final item = OpSuchtItem.fromJson(json);
                if (item.internalname.isNotEmpty || item.displayname.isNotEmpty) {
                  loaded.add(item);
                }
              }
            }
          } catch (e) {
            debugPrint('[OpSucht] Item $name Fehler: $e');
            // Lokale Kopie als Fallback
            if (await cacheFile.exists()) {
              try {
                final json = jsonDecode(await cacheFile.readAsString());
                if (json is Map<String, dynamic>) {
                  final item = OpSuchtItem.fromJson(json);
                  if (item.internalname.isNotEmpty || item.displayname.isNotEmpty) {
                    loaded.add(item);
                  }
                }
              } catch (_) {}
            }
          }
        }));
      }

      if (loaded.isEmpty) return false;

      loaded.sort((a, b) {
        final nameA = a.displayname.isNotEmpty ? a.displayname : a.internalname;
        final nameB = b.displayname.isNotEmpty ? b.displayname : b.internalname;
        return nameA.toLowerCase().compareTo(nameB.toLowerCase());
      });

      _items = loaded;
      await _setTimestamp('items');
      debugPrint('[OpSucht] $label: ${loaded.length} Items geladen');
      return true;

    } catch (e) {
      debugPrint('[OpSucht] $label Fehler: $e');
      if (_items.isEmpty) await _loadItemsFromCache();
      return false;
    }
  }

  // ── Manueller Refresh ─────────────────────────────────────
  //
  //  Löscht Timestamps + Season-Cache → erzwingt kompletten Neu-Download.

  Future<void> forceRefreshAll() async {
    debugPrint('[OpSucht] Force-Refresh');

    try {
      final dir  = await getApplicationDocumentsDirectory();
      final base = '${dir.path}/opsucht';
      for (final key in ['season', 'items']) {
        final ts = File('$base/.ts_$key');
        if (await ts.exists()) await ts.delete();
      }
      final seasonFile = File('$base/config/season.json');
      if (await seasonFile.exists()) await seasonFile.delete();
    } catch (_) {}

    _seasonLoaded = false;
    _itemsLoaded  = false;
    notifyListeners();

    await loadSeason(force: true);
    await loadItems(force: true);
  }

  // ── Suche ─────────────────────────────────────────────────
  //
  //  Durchsucht displayname, internalname, material.
  //  Groß-/Kleinschreibung wird ignoriert.

  List<OpSuchtItem> search(String query) {
    if (query.trim().isEmpty) return _items;
    final q = query.trim().toLowerCase();
    return _items.where((item) => item.searchIndex.contains(q)).toList();
  }
}
