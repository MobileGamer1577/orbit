import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../storage/collection_store.dart';
import '../theme/orbit_theme.dart';
import '../widgets/festival_song_details_sheet.dart';
import '../widgets/orbit_glass_card.dart';
import '../services/festival_api_service.dart';

// ─────────────────────────────────────────────────────────────
// Public enum – wird auch in FortniteHubScreen verwendet
// ─────────────────────────────────────────────────────────────

enum LockerMode { all, owned, wishlist }

// ─────────────────────────────────────────────────────────────
// Interner Filter (nur bei mode == all sichtbar)
// ─────────────────────────────────────────────────────────────

enum _LockerFilter { all, owned, wishlist }

class FortniteLockerScreen extends StatefulWidget {
  final CollectionStore collection;

  /// Wenn [mode] auf owned oder wishlist gesetzt wird:
  /// - Filter-Tabs werden ausgeblendet
  /// - Liste zeigt direkt nur die passenden Songs
  final LockerMode mode;

  const FortniteLockerScreen({
    super.key,
    required this.collection,
    this.mode = LockerMode.all,
  });

  @override
  State<FortniteLockerScreen> createState() => _FortniteLockerScreenState();
}

class _FortniteLockerScreenState extends State<FortniteLockerScreen> {
  final TextEditingController _search = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  List<FestivalSongDetails> _songs = [];
  bool _loading = true;
  String _query = '';
  late _LockerFilter _filter;

  @override
  void initState() {
    super.initState();
    // Startfilter aus übergebenem Mode ableiten
    _filter = switch (widget.mode) {
      LockerMode.owned    => _LockerFilter.owned,
      LockerMode.wishlist => _LockerFilter.wishlist,
      LockerMode.all      => _LockerFilter.all,
    };
    _loadAll();
    _search.addListener(() => setState(() => _query = _search.text.trim()));
  }

  @override
  void dispose() {
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
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
      } else if (decoded is List) {
        _songs = decoded
            .whereType<Map<String, dynamic>>()
            .map(FestivalSongDetails.fromMap)
            .where((s) => s.songId.trim().isNotEmpty)
            .toList();
      }
    } catch (_) {
      _songs = [];
    }
  }

  List<FestivalSongDetails> _filtered() {
    final q = _query.toLowerCase();
    final owned   = widget.collection.owned(CollectionStore.categoryFestivalSong);
    final wished  = widget.collection.wishlist(CollectionStore.categoryFestivalSong);

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

  // ── Titel & Untertitel je nach Mode ─────────────────────────

  String _screenTitle(AppLocalizations l10n) => switch (widget.mode) {
    LockerMode.owned    => l10n.lockerTitle,
    LockerMode.wishlist => l10n.filterWishlist,
    LockerMode.all      => l10n.lockerTitle,
  };

  String _screenSubtitle(AppLocalizations l10n) => switch (widget.mode) {
    LockerMode.owned    => l10n.lockerSubtitleOwned,
    LockerMode.wishlist => l10n.lockerSubtitleWishlist,
    LockerMode.all      => l10n.lockerSubtitle,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final list = _filtered();

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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _screenTitle(l10n),
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            _screenSubtitle(l10n),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.50),
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // ── Suchfeld ──────────────────────────────
                OrbitGlassCard(
                  child: TextField(
                    controller: _search,
                    focusNode: _searchFocus,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: l10n.lockerSearchHint,
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.40),
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Colors.white.withOpacity(0.55),
                      ),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear,
                                color: Colors.white.withOpacity(0.55),
                              ),
                              onPressed: () => _search.clear(),
                            )
                          : null,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // ── Filter-Tabs (nur bei mode == all) ─────
                if (widget.mode == LockerMode.all) ...[
                  _FilterRow(
                    value: _filter,
                    onChanged: (v) => setState(() => _filter = v),
                    l10n: l10n,
                  ),
                  const SizedBox(height: 12),
                ],

                // ── Liste ─────────────────────────────────
                Expanded(
                  child: _loading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF9C6FFF),
                          ),
                        )
                      : list.isEmpty
                      ? _EmptyState(mode: widget.mode, l10n: l10n)
                      : AnimatedBuilder(
                          animation: widget.collection,
                          builder: (context, _) => ListView.separated(
                            physics: const BouncingScrollPhysics(),
                            itemCount: list.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, i) {
                              final song = list[i];
                              return _LockerTile(
                                song: song,
                                collection: widget.collection,
                                onTap: () => showFestivalSongDetailsSheet(
                                  context,
                                  song: song,
                                  collection: widget.collection,
                                ),
                              );
                            },
                          ),
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

// ─────────────────────────────────────────────────────────────
// Empty-State mit hilfreicher Nachricht je nach Mode
// ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final LockerMode mode;
  final AppLocalizations l10n;
  const _EmptyState({required this.mode, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final icon = switch (mode) {
      LockerMode.owned    => Icons.inventory_2_outlined,
      LockerMode.wishlist => Icons.favorite_border,
      LockerMode.all      => Icons.search_off,
    };
    final text = switch (mode) {
      LockerMode.owned    => l10n.lockerEmptyOwned,
      LockerMode.wishlist => l10n.lockerEmptyWishlist,
      LockerMode.all      => l10n.noResults,
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white.withOpacity(0.20), size: 52),
            const SizedBox(height: 16),
            Text(
              text,
              style: TextStyle(
                color: Colors.white.withOpacity(0.45),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Filter-Row (nur bei LockerMode.all)
// ─────────────────────────────────────────────────────────────

class _FilterRow extends StatelessWidget {
  final _LockerFilter value;
  final ValueChanged<_LockerFilter> onChanged;
  final AppLocalizations l10n;

  const _FilterRow({
    required this.value,
    required this.onChanged,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Tab(
          label: l10n.filterAll,
          active: value == _LockerFilter.all,
          onTap: () => onChanged(_LockerFilter.all),
        ),
        const SizedBox(width: 8),
        _Tab(
          label: l10n.filterOwned,
          active: value == _LockerFilter.owned,
          onTap: () => onChanged(_LockerFilter.owned),
        ),
        const SizedBox(width: 8),
        _Tab(
          label: l10n.filterWishlist,
          active: value == _LockerFilter.wishlist,
          onTap: () => onChanged(_LockerFilter.wishlist),
        ),
      ],
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _Tab({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: active
            ? const Color(0xFF7C4DFF).withOpacity(0.28)
            : Colors.white.withOpacity(0.07),
        border: Border.all(
          color: active
              ? const Color(0xFF9C6FFF).withOpacity(0.60)
              : Colors.white.withOpacity(0.10),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active ? Colors.white : Colors.white.withOpacity(0.55),
          fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          fontSize: 13,
        ),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────
// Locker-Tile
// ─────────────────────────────────────────────────────────────

class _LockerTile extends StatelessWidget {
  final FestivalSongDetails song;
  final CollectionStore collection;
  final VoidCallback onTap;

  const _LockerTile({
    required this.song,
    required this.collection,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final owned = collection.isOwned(
      CollectionStore.categoryFestivalSong,
      song.songId,
    );
    final wished = collection.isWished(
      CollectionStore.categoryFestivalSong,
      song.songId,
    );
    final api = FestivalApiService.instance.lookup(song.songId);
    final hasDiff = api != null && api.difficulty.hasAny;

    return OrbitGlassCard(
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          child: Row(
            children: [
              _MiniAlbumCover(url: api?.albumArt),
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
                      _MiniDiffBars(difficulty: api.difficulty),
                    ],
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (owned)
                    const Icon(
                      Icons.check_circle,
                      color: Color(0xFF00E676),
                      size: 18,
                    ),
                  if (wished)
                    const Icon(
                      Icons.favorite,
                      color: Color(0xFFFF4081),
                      size: 18,
                    ),
                ],
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right,
                color: Colors.white.withOpacity(0.30),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniAlbumCover extends StatelessWidget {
  final String? url;
  const _MiniAlbumCover({this.url});

  @override
  Widget build(BuildContext context) => Container(
    width: 48,
    height: 48,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(10),
      color: Colors.white.withOpacity(0.07),
      border: Border.all(color: Colors.white.withOpacity(0.10)),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(9),
      child: (url != null && url!.isNotEmpty)
          ? Image.network(
              url!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _icon(),
            )
          : _icon(),
    ),
  );

  Widget _icon() =>
      Icon(Icons.music_note, color: Colors.white.withOpacity(0.30), size: 22);
}

class _MiniDiffBars extends StatelessWidget {
  final SongDifficulty difficulty;
  const _MiniDiffBars({required this.difficulty});

  @override
  Widget build(BuildContext context) {
    final instruments = [
      (difficulty.vocals, const Color(0xFFFF6EC7)),
      (difficulty.guitar, const Color(0xFFFFD600)),
      (difficulty.bass, const Color(0xFF40C4FF)),
      (difficulty.drums, const Color(0xFFFF5252)),
    ];
    return Row(
      children: instruments.map((e) {
        if (e.$1 == 0) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(right: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              7,
              (i) => Container(
                width: 5,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  color: i < e.$1 ? e.$2 : e.$2.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
