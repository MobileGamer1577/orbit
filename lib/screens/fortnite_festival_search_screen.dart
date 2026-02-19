import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../theme/orbit_theme.dart';

class FestivalSong {
  final String sid; // SID_Placeholder_...
  final String song;
  final String artist;
  final String songWithArtist;
  final String source;
  final String sourceSeason;
  final int? bpm;
  final String announceDate; // YYYY-MM-DD oder Text
  final bool proVocals;

  FestivalSong({
    required this.sid,
    required this.song,
    required this.artist,
    required this.songWithArtist,
    required this.source,
    required this.sourceSeason,
    required this.bpm,
    required this.announceDate,
    required this.proVocals,
  });

  factory FestivalSong.fromJson(Map<String, dynamic> j) {
    return FestivalSong(
      sid: (j['sid'] ?? '').toString().trim(),
      song: (j['song'] ?? '').toString().trim(),
      artist: (j['artist'] ?? '').toString().trim(),
      songWithArtist: (j['song_with_artist'] ?? j['songWithArtist'] ?? '')
          .toString()
          .trim(),
      source: (j['source'] ?? '').toString().trim(),
      sourceSeason: (j['source_season'] ?? j['sourceSeason'] ?? '')
          .toString()
          .trim(),
      bpm: j['bpm'] is int
          ? j['bpm'] as int
          : int.tryParse((j['bpm'] ?? '').toString()),
      announceDate: (j['announce_date'] ?? j['announceDate'] ?? '')
          .toString()
          .trim(),
      proVocals: (j['pro_vocals'] ?? j['proVocals'] ?? false) == true,
    );
  }
}

class FortniteFestivalSearchScreen extends StatefulWidget {
  const FortniteFestivalSearchScreen({super.key});

  @override
  State<FortniteFestivalSearchScreen> createState() =>
      _FortniteFestivalSearchScreenState();
}

class _FortniteFestivalSearchScreenState
    extends State<FortniteFestivalSearchScreen> {
  static const String _assetPath = 'assets/data/festival_songs.json';

  final _controller = TextEditingController();
  List<FestivalSong> _all = const [];
  List<FestivalSong> _filtered = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    _controller.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _controller.removeListener(_applyFilter);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final raw = await rootBundle.loadString(_assetPath);
      final decoded = jsonDecode(raw);

      final List<dynamic> list;
      if (decoded is Map<String, dynamic> && decoded['songs'] is List) {
        list = decoded['songs'] as List<dynamic>;
      } else if (decoded is List) {
        list = decoded;
      } else {
        throw Exception('festival_songs.json: unerwartetes Format');
      }

      final songs = list
          .whereType<Map>()
          .map((m) => FestivalSong.fromJson(Map<String, dynamic>.from(m)))
          .where((s) => s.sid.isNotEmpty)
          .toList();

      songs.sort(
        (a, b) => a.song.toLowerCase().compareTo(b.song.toLowerCase()),
      );

      _all = songs;
      _filtered = songs;
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyFilter() {
    final q = _controller.text.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() => _filtered = _all);
      return;
    }

    bool match(FestivalSong s) {
      final hay = [
        s.song,
        s.artist,
        s.songWithArtist,
        s.sid,
        s.source,
        s.sourceSeason,
      ].join(' ').toLowerCase();

      return hay.contains(q);
    }

    setState(() => _filtered = _all.where(match).toList());
  }

  Future<void> _openDetails(FestivalSong s) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.song.isNotEmpty ? s.song : s.songWithArtist),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (s.artist.isNotEmpty) Text('Artist: ${s.artist}'),
            const SizedBox(height: 8),
            Text('Song ID: ${s.sid}'),
            if (s.bpm != null) ...[
              const SizedBox(height: 8),
              Text('BPM: ${s.bpm}'),
            ],
            if (s.announceDate.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Erschienen: ${s.announceDate}'),
            ],
            if (s.source.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Quelle: ${s.source}${s.sourceSeason.isNotEmpty ? ' • ${s.sourceSeason}' : ''}',
              ),
            ],
            const SizedBox(height: 8),
            Text('Pro Gesang: ${s.proVocals ? 'Ja' : 'Nein'}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: OrbitBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Songs suchen',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _load,
                      tooltip: 'Neu laden',
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                TextField(
                  controller: _controller,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Song / Artist / ID…',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.08),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.10),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.10),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.25),
                      ),
                    ),
                    suffixIcon: _controller.text.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _controller.clear();
                              _applyFilter();
                            },
                            icon: const Icon(Icons.close),
                          ),
                  ),
                ),
                const SizedBox(height: 10),

                if (_loading)
                  const Padding(
                    padding: EdgeInsets.only(top: 18),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 18),
                    child: Text(
                      'Fehler: $_error',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.redAccent),
                    ),
                  )
                else ...[
                  Text(
                    '${_filtered.length} / ${_all.length} Songs',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.white60),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.separated(
                      itemCount: _filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final s = _filtered[i];
                        final subtitleParts = <String>[];
                        if (s.artist.isNotEmpty) subtitleParts.add(s.artist);
                        if (s.bpm != null) subtitleParts.add('${s.bpm} BPM');
                        if (s.proVocals) subtitleParts.add('Pro Vocals');
                        final subtitle = subtitleParts.join(' • ');

                        return InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () => _openDetails(s),
                          child: Ink(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.08),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.music_note, size: 22),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        s.song.isNotEmpty
                                            ? s.song
                                            : s.songWithArtist,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w900,
                                            ),
                                      ),
                                      if (subtitle.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          subtitle,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(color: Colors.white70),
                                        ),
                                      ],
                                      const SizedBox(height: 4),
                                      Text(
                                        s.sid,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(color: Colors.white60),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right, size: 26),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
