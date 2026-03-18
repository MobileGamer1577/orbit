import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../widgets/orbit_glass_card.dart';
import '../storage/collection_store.dart';
import '../theme/orbit_theme.dart';
import '../widgets/festival_song_details_sheet.dart';
import '../services/festival_api_service.dart';

class FortniteFestivalSearchScreen extends StatefulWidget {
  final CollectionStore collection;

  const FortniteFestivalSearchScreen({super.key, required this.collection});

  @override
  State<FortniteFestivalSearchScreen> createState() =>
      _FortniteFestivalSearchScreenState();
}

class _FortniteFestivalSearchScreenState
    extends State<FortniteFestivalSearchScreen> {
  final TextEditingController _controller = TextEditingController();

  List<FestivalSongDetails> _songs    = [];
  List<FestivalSongDetails> _filtered = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    _controller.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      await Future.wait([
        _loadSongs(),
        FestivalApiService.instance.ensureLoaded(),
      ]);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadSongs() async {
    try {
      final jsonStr = await rootBundle.loadString(
        'assets/data/festival_songs.json',
      );
      final decoded = jsonDecode(jsonStr);

      if (decoded is Map<String, dynamic> && decoded['songs'] is List) {
        final songsList = decoded['songs'] as List;
        _songs = songsList
            .whereType<Map<String, dynamic>>()
            .map(FestivalSongDetails.fromMap)
            .where((s) => s.songId.trim().isNotEmpty)
            .toList();
        _songs.sort(
            (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        _filtered = List.of(_songs);
      }
    } catch (_) {
      _songs    = [];
      _filtered = [];
    }
  }

  void _applyFilter() {
    final q = _controller.text.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filtered = List.of(_songs);
      } else {
        _filtered = _songs.where((s) {
          final blob = '${s.title} ${s.artist} ${s.songId}'.toLowerCase();
          return blob.contains(q);
        }).toList();
      }
    });
  }

  void _openDetails(FestivalSongDetails song) {
    showFestivalSongDetailsSheet(
      context,
      song:       song,
      collection: widget.collection,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: OrbitBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ───────────────────────────────
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        l10n.festivalSearchTitle,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // ── Suchfeld ──────────────────────────────
                OrbitGlassCard(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: l10n.festivalSearchHint,
                      hintStyle:
                          TextStyle(color: Colors.white.withOpacity(0.40)),
                      prefixIcon: Icon(Icons.search,
                          color: Colors.white.withOpacity(0.55)),
                      suffixIcon: _controller.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear,
                                  color: Colors.white.withOpacity(0.55)),
                              onPressed: () => _controller.clear(),
                            )
                          : null,
                      border:        InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // ── Ergebnis-Zähler ───────────────────────
                if (!_loading)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 6),
                    child: Text(
                      l10n.festivalSongCount(_filtered.length),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.40),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                // ── Liste ─────────────────────────────────
                Expanded(
                  child: _loading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFF9C6FFF)),
                        )
                      : _filtered.isEmpty
                          ? Center(
                              child: Text(
                                l10n.noResults,
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.45)),
                              ),
                            )
                          : ListView.separated(
                              physics: const BouncingScrollPhysics(),
                              itemCount: _filtered.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, i) {
                                final song = _filtered[i];
                                return _SongTile(
                                  song:       song,
                                  collection: widget.collection,
                                  onTap: () => _openDetails(song),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SongTile extends StatelessWidget {
  final FestivalSongDetails song;
  final CollectionStore     collection;
  final VoidCallback        onTap;

  const _SongTile({
    required this.song,
    required this.collection,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: collection,
      builder: (context, _) {
        final owned  = collection.isOwned(CollectionStore.categoryFestivalSong, song.songId);
        final wished = collection.isWished(CollectionStore.categoryFestivalSong, song.songId);
        final apiData = FestivalApiService.instance.lookup(song.songId);
        final hasDiff = apiData != null && apiData.difficulty.hasAny;

        return OrbitGlassCard(
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
              child: Row(
                children: [
                  _MiniAlbumCover(url: apiData?.albumArt),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          song.title.isEmpty ? '???' : song.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          song.artist.isEmpty ? '???' : song.artist,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.55),
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (hasDiff) ...[
                          const SizedBox(height: 6),
                          _MiniDifficultyBars(difficulty: apiData!.difficulty),
                        ],
                      ],
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (owned)
                        const Icon(Icons.check_circle,
                            color: Color(0xFF00E676), size: 18),
                      if (wished)
                        const Icon(Icons.favorite,
                            color: Color(0xFFFF4081), size: 18),
                    ],
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right,
                      color: Colors.white.withOpacity(0.30), size: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MiniDifficultyBars extends StatelessWidget {
  final SongDifficulty difficulty;
  const _MiniDifficultyBars({required this.difficulty});

  @override
  Widget build(BuildContext context) {
    final instruments = [
      (difficulty.vocals, const Color(0xFFFF6EC7)),
      (difficulty.guitar, const Color(0xFFFFD600)),
      (difficulty.bass,   const Color(0xFF40C4FF)),
      (difficulty.drums,  const Color(0xFFFF5252)),
    ];
    return Row(
      children: instruments.map((entry) {
        final value = entry.$1;
        final color = entry.$2;
        if (value == 0) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(right: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(7, (i) => Container(
              width: 5, height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: i < value ? color : color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(2),
              ),
            )),
          ),
        );
      }).toList(),
    );
  }
}

class _MiniAlbumCover extends StatelessWidget {
  final String? url;
  const _MiniAlbumCover({required this.url});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48, height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.white.withOpacity(0.07),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: (url != null && url!.isNotEmpty)
            ? Image.network(url!, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _icon())
            : _icon(),
      ),
    );
  }

  Widget _icon() => Icon(Icons.music_note,
      color: Colors.white.withOpacity(0.30), size: 22);
}
