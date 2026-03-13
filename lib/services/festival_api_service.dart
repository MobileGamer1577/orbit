import 'dart:convert';
import 'package:http/http.dart' as http;

/// Schwierigkeitsgrad eines Songs pro Instrument (0 = nicht verfügbar, 1–7 Striche)
class SongDifficulty {
  final int vocals;      // Gesang
  final int guitar;      // Lead-Gitarre
  final int bass;        // Bass
  final int drums;       // Schlagzeug
  final int plasticGuitar; // Pro-Gitarre (falls vorhanden)
  final int plasticBass;   // Pro-Bass
  final int plasticDrums;  // Pro-Schlagzeug

  const SongDifficulty({
    this.vocals      = 0,
    this.guitar      = 0,
    this.bass        = 0,
    this.drums       = 0,
    this.plasticGuitar = 0,
    this.plasticBass   = 0,
    this.plasticDrums  = 0,
  });

  /// Gibt true zurück wenn mindestens ein Instrument vorhanden ist
  bool get hasAny =>
      vocals > 0 || guitar > 0 || bass > 0 || drums > 0;

  factory SongDifficulty.fromJson(Map<String, dynamic> j) {
    int pick(String key) => (j[key] as num?)?.toInt() ?? 0;
    return SongDifficulty(
      vocals:        pick('vocals'),
      guitar:        pick('guitar'),
      bass:          pick('bass'),
      drums:         pick('drums'),
      plasticGuitar: pick('plasticGuitar'),
      plasticBass:   pick('plasticBass'),
      plasticDrums:  pick('plasticDrums'),
    );
  }
}

/// Alle Track-Daten die wir aus der API brauchen
class TrackApiData {
  final String id;
  final String name;
  final String artist;
  final String albumArt;   // Albumcover-URL
  final SongDifficulty difficulty;
  final int durationSeconds;

  const TrackApiData({
    required this.id,
    required this.name,
    required this.artist,
    required this.albumArt,
    required this.difficulty,
    required this.durationSeconds,
  });

  factory TrackApiData.fromJson(Map<String, dynamic> j) {
    // Bilder
    final images = j['images'] as Map<String, dynamic>?;
    final albumArt = images?['album']     as String?
                  ?? images?['icon']      as String?
                  ?? images?['featured']  as String?
                  ?? '';

    // Difficulty
    final diffRaw = j['difficulty'];
    final diff = diffRaw is Map
        ? SongDifficulty.fromJson(Map<String, dynamic>.from(diffRaw))
        : const SongDifficulty();

    return TrackApiData(
      id:              (j['id']     as String?) ?? '',
      name:            (j['name']   as String?) ?? '',
      artist:          (j['artist'] as String?) ?? '',
      albumArt:        albumArt,
      difficulty:      diff,
      durationSeconds: (j['duration'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Singleton-Service: lädt /v2/cosmetics/tracks einmalig und cached
class FestivalApiService {
  static const _url = 'https://fortnite-api.com/v2/cosmetics/tracks';
  static const _apiKey = '135f01ed-1a5e-40df-b8b6-4b2c97f47151';

  static FestivalApiService? _instance;
  static FestivalApiService get instance =>
      _instance ??= FestivalApiService._();

  FestivalApiService._();

  /// Map: lowercase(id) → TrackApiData
  Map<String, TrackApiData>? _cache;
  bool _loading = false;

  bool get isLoaded => _cache != null;

  /// Gibt TrackApiData für eine SID zurück (case-insensitive)
  TrackApiData? lookup(String sid) {
    if (_cache == null) return null;
    return _cache![sid.toLowerCase()];
  }

  /// Lädt die Tracks-API (falls noch nicht geladen)
  Future<void> ensureLoaded() async {
    if (_cache != null) return;
    if (_loading) {
      // Warte bis der laufende Load fertig ist
      while (_loading) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return;
    }
    _loading = true;
    try {
      final res = await http.get(
        Uri.parse(_url),
        headers: {
          'Authorization': _apiKey,
          'Accept': 'application/json',
          'User-Agent': 'Orbit/1.0',
        },
      ).timeout(const Duration(seconds: 30));

      if (res.statusCode == 200) {
        final json   = jsonDecode(res.body) as Map<String, dynamic>;
        final data   = json['data'];
        final list   = data is List ? data : <dynamic>[];

        final map = <String, TrackApiData>{};
        for (final raw in list) {
          if (raw is Map) {
            final track = TrackApiData.fromJson(Map<String, dynamic>.from(raw));
            if (track.id.isNotEmpty) {
              map[track.id.toLowerCase()] = track;
            }
          }
        }
        _cache = map;
      }
    } catch (_) {
      // API-Fehler ist nicht kritisch — App läuft ohne Difficulty-Daten
      _cache = {};
    } finally {
      _loading = false;
    }
  }

  /// Cache leeren (z.B. für manuellen Refresh)
  void clearCache() => _cache = null;
}
