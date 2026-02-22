import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../storage/collection_store.dart';
import '../theme/orbit_theme.dart';
import '../widgets/festival_song_details_sheet.dart';
import '../widgets/orbit_glass_card.dart';

enum _LockerFilter { all, owned, wishlist }

class FortniteLockerScreen extends StatefulWidget {
  final CollectionStore collection;

  const FortniteLockerScreen({super.key, required this.collection});

  @override
  State<FortniteLockerScreen> createState() => _FortniteLockerScreenState();
}

class _FortniteLockerScreenState extends State<FortniteLockerScreen> {
  final TextEditingController _search = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  List<FestivalSongDetails> _songs = [];
  bool _loading = true;
  String _query = '';
  _LockerFilter _filter = _LockerFilter.all;

  @override
  void initState() {
    super.initState();
    _loadSongs();
    _search.addListener(() => setState(() => _query = _search.text.trim()));
  }

  @override
  void dispose() {
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _loadSongs() async {
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
      }
    } catch (_) {
      _songs = [];
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<FestivalSongDetails> _filtered() {
    final q = _query.toLowerCase();

    final owned = widget.collection.owned(CollectionStore.categoryFestivalSong);
    final wished = widget.collection.wishlist(
      CollectionStore.categoryFestivalSong,
    );

    bool match(FestivalSongDetails s) {
      final blob = '${s.title} ${s.artist} ${s.songId}'.toLowerCase();
      if (q.isNotEmpty && !blob.contains(q)) return false;

      switch (_filter) {
        case _LockerFilter.all:
          return true;
        case _LockerFilter.owned:
          return owned.contains(s.songId);
        case _LockerFilter.wishlist:
          return wished.contains(s.songId);
      }
    }

    final list = _songs.where(match).toList();
    list.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered();

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
                        'Spind',
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
                Text(
                  'Alle Cosmetics (aktuell: Festival-Songs)\nSpäter: kompletter Fortnite-Spind via Account-Verknüpfung/API.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.65),
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 14),
                _SearchBar(
                  controller: _search,
                  focusNode: _searchFocus,
                  onClear: () => _search.clear(),
                ),
                const SizedBox(height: 10),
                _FilterRow(
                  value: _filter,
                  onChanged: (v) => setState(() => _filter = v),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : list.isEmpty
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
                              itemCount: list.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, i) {
                                final s = list[i];

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

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onClear;

  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return OrbitGlassCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(Icons.search, color: Colors.white.withOpacity(0.65)),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
                decoration: InputDecoration(
                  hintText: 'Suchen: Song, Artist oder Song ID…',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.45)),
                  border: InputBorder.none,
                ),
              ),
            ),
            if (controller.text.isNotEmpty)
              IconButton(
                onPressed: onClear,
                icon: Icon(Icons.close, color: Colors.white.withOpacity(0.8)),
              ),
          ],
        ),
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  final _LockerFilter value;
  final ValueChanged<_LockerFilter> onChanged;

  const _FilterRow({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Widget chip(_LockerFilter v, String label, IconData icon) {
      final selected = value == v;
      return InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => onChanged(v),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: selected
                ? Colors.white.withOpacity(0.14)
                : Colors.white.withOpacity(0.07),
            border: Border.all(
              color: Colors.white.withOpacity(selected ? 0.22 : 0.10),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: Colors.white.withOpacity(0.9)),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.92),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          chip(_LockerFilter.all, 'Alle', Icons.apps),
          const SizedBox(width: 10),
          chip(_LockerFilter.owned, 'Im Besitz', Icons.check_circle),
          const SizedBox(width: 10),
          chip(_LockerFilter.wishlist, 'Wunschliste', Icons.favorite),
        ],
      ),
    );
  }
}
