import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/orbit_glass_card.dart';

import '../storage/collection_store.dart';
import '../theme/orbit_theme.dart';
import '../widgets/festival_song_details_sheet.dart';

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

  List<FestivalSongDetails> _songs = [];
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
      final jsonStr = await rootBundle.loadString(
        'assets/data/festival_songs.json',
      );
      final decoded = jsonDecode(jsonStr);
      if (decoded is List) {
        _songs = decoded
            .whereType<Map<String, dynamic>>()
            .map(FestivalSongDetails.fromMap)
            .where((s) => s.songId.trim().isNotEmpty)
            .toList();
        _songs.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
      }
      _applyFilter();
    } catch (_) {
      _songs = [];
      _filtered = [];
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyFilter() {
    final q = _controller.text.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() => _filtered = List.of(_songs));
      return;
    }

    setState(() {
      _filtered = _songs.where((s) {
        final blob = '${s.title} ${s.artist} ${s.songId}'.toLowerCase();
        return blob.contains(q);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: OrbitBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const SizedBox(width: 6),
                    const Expanded(
                      child: Text(
                        'Songs suchen',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                OrbitGlassCard(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search,
                          color: Colors.white.withOpacity(0.65),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Suche nach Song, Artist oder Song ID…',
                              hintStyle: TextStyle(
                                color: Colors.white.withOpacity(0.45),
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        if (_controller.text.isNotEmpty)
                          IconButton(
                            onPressed: () {
                              _controller.clear();
                              _applyFilter();
                            },
                            icon: Icon(
                              Icons.close,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _filtered.isEmpty
                      ? Center(
                          child: Text(
                            'Keine Treffer.',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.65),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                      : AnimatedBuilder(
                          animation: widget.collection,
                          builder: (context, _) {
                            return ListView.separated(
                              physics: const BouncingScrollPhysics(),
                              itemCount: _filtered.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, i) {
                                final s = _filtered[i];

                                final owned = widget.collection.isOwned(
                                  CollectionStore.categoryFestivalSong,
                                  s.songId,
                                );
                                final wished = widget.collection.isWished(
                                  CollectionStore.categoryFestivalSong,
                                  s.songId,
                                );

                                return OrbitGlassCard(
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    title: Text(
                                      s.title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${s.artist} • ${s.songId}',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (owned)
                                          Icon(
                                            Icons.check_circle,
                                            color: Colors.white.withOpacity(
                                              0.90,
                                            ),
                                            size: 20,
                                          ),
                                        if (owned) const SizedBox(width: 8),
                                        if (wished)
                                          Icon(
                                            Icons.favorite,
                                            color: Colors.white.withOpacity(
                                              0.90,
                                            ),
                                            size: 20,
                                          ),
                                        const SizedBox(width: 10),
                                        Icon(
                                          Icons.chevron_right,
                                          color: Colors.white.withOpacity(0.7),
                                        ),
                                      ],
                                    ),
                                    onTap: () => showFestivalSongDetailsSheet(
                                      context,
                                      song: s,
                                      collection: widget.collection,
                                    ),
                                  ),
                                );
                              },
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
