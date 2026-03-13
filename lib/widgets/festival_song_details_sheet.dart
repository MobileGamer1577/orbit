import 'package:flutter/material.dart';

import '../services/festival_api_service.dart';
import '../storage/collection_store.dart';

// ─────────────────────────────────────────────────────────
// Datenmodell
// ─────────────────────────────────────────────────────────

class FestivalSongDetails {
  final String title;
  final String artist;
  final String songId;
  final String source;
  final String bpm;
  final String released;
  final bool   hasVocalPro;

  const FestivalSongDetails({
    required this.title,
    required this.artist,
    required this.songId,
    required this.source,
    required this.bpm,
    required this.released,
    required this.hasVocalPro,
  });

  factory FestivalSongDetails.fromMap(Map<String, dynamic> m) {
    String pick(String key) {
      final v = m[key];
      if (v == null) return '';
      return v.toString();
    }

    bool pickBool(String key) {
      final v = m[key];
      if (v is bool) return v;
      final s = (v ?? '').toString().toLowerCase().trim();
      return s == 'true' || s == 'yes' || s == '1' || s == 'ja';
    }

    // Hinweis: In der festival_songs.json ist "song" = Interpret und "artist" = Titel
    return FestivalSongDetails(
      title:       pick('artist'),
      artist:      pick('song'),
      songId:      pick('sid'),
      source:      pick('source'),
      bpm:         pick('bpm'),
      released:    pick('announce_date'),
      hasVocalPro: pickBool('pro_vocals'),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Bottom Sheet öffnen
// ─────────────────────────────────────────────────────────

Future<void> showFestivalSongDetailsSheet(
  BuildContext context, {
  required FestivalSongDetails song,
  required CollectionStore collection,
}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _FestivalSongSheet(song: song, collection: collection),
  );
}

// ─────────────────────────────────────────────────────────
// Sheet-Widget
// ─────────────────────────────────────────────────────────

class _FestivalSongSheet extends StatefulWidget {
  final FestivalSongDetails song;
  final CollectionStore     collection;

  const _FestivalSongSheet({required this.song, required this.collection});

  @override
  State<_FestivalSongSheet> createState() => _FestivalSongSheetState();
}

class _FestivalSongSheetState extends State<_FestivalSongSheet> {
  TrackApiData? _apiData;
  bool          _apiLoading = true;

  @override
  void initState() {
    super.initState();
    _loadApiData();
  }

  Future<void> _loadApiData() async {
    await FestivalApiService.instance.ensureLoaded();
    if (mounted) {
      setState(() {
        _apiData    = FestivalApiService.instance.lookup(widget.song.songId);
        _apiLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final song   = widget.song;
    final radius = BorderRadius.circular(22);
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedBuilder(
      animation: widget.collection,
      builder: (context, _) {
        final owned = widget.collection.isOwned(
            CollectionStore.categoryFestivalSong, song.songId);
        final wished = widget.collection.isWished(
            CollectionStore.categoryFestivalSong, song.songId);

        return Padding(
          padding: EdgeInsets.only(left: 12, right: 12, bottom: 12 + bottom),
          child: ClipRRect(
            borderRadius: radius,
            child: Material(
              color: const Color(0xFF1A1026).withOpacity(0.95),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header: Albumcover + Titel ────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Albumcover (aus API oder Platzhalter)
                        _AlbumCover(
                          url:     _apiData?.albumArt,
                          loading: _apiLoading,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                song.title.isEmpty ? '???' : song.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                song.artist.isEmpty ? '???' : song.artist,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.65),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 10),
                              // Owned / Wished Chips
                              Wrap(
                                spacing: 8,
                                children: [
                                  _ActionChip(
                                    icon:    owned ? Icons.check_circle : Icons.check_circle_outline,
                                    label:   owned ? 'Im Besitz' : 'Besitzen',
                                    active:  owned,
                                    color:   const Color(0xFF00E676),
                                    onTap:   () => widget.collection.toggleOwned(
                                        CollectionStore.categoryFestivalSong, song.songId),
                                  ),
                                  _ActionChip(
                                    icon:    wished ? Icons.favorite : Icons.favorite_border,
                                    label:   wished ? 'Auf Wunschliste' : 'Wunschliste',
                                    active:  wished,
                                    color:   const Color(0xFFFF4081),
                                    onTap:   () => widget.collection.toggleWished(
                                        CollectionStore.categoryFestivalSong, song.songId),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),
                    _Divider(),

                    // ── Schwierigkeitsgrad ────────────────
                    const SizedBox(height: 14),
                    _SectionLabel('Schwierigkeit'),
                    const SizedBox(height: 10),

                    if (_apiLoading)
                      _DifficultyLoading()
                    else if (_apiData != null && _apiData!.difficulty.hasAny)
                      _DifficultyWidget(difficulty: _apiData!.difficulty)
                    else
                      Text(
                        'Keine Daten verfügbar',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.35),
                            fontSize: 13),
                      ),

                    const SizedBox(height: 16),
                    _Divider(),

                    // ── Song-Infos ────────────────────────
                    const SizedBox(height: 14),
                    _SectionLabel('Details'),
                    const SizedBox(height: 10),

                    _InfoRow('Quelle',    song.source.isEmpty ? '—' : song.source),
                    if (song.bpm.isNotEmpty && song.bpm != '0')
                      _InfoRow('BPM', song.bpm),
                    if (song.released.isNotEmpty)
                      _InfoRow('Hinzugefügt', song.released),
                    if (_apiData != null && _apiData!.durationSeconds > 0)
                      _InfoRow('Länge', _formatDuration(_apiData!.durationSeconds)),
                    _InfoRow('Vocal Pro', song.hasVocalPro ? 'Ja ✓' : 'Nein'),
                    _InfoRow('Song-ID', song.songId.isEmpty ? '—' : song.songId),

                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

// ─────────────────────────────────────────────────────────
// Difficulty-Widget — zeigt Striche pro Instrument
// ─────────────────────────────────────────────────────────

class _DifficultyWidget extends StatelessWidget {
  final SongDifficulty difficulty;

  const _DifficultyWidget({required this.difficulty});

  @override
  Widget build(BuildContext context) {
    final instruments = [
      _InstrumentData(
        label:  'Gesang',
        icon:   Icons.mic,
        color:  const Color(0xFFFF6EC7),
        value:  difficulty.vocals,
      ),
      _InstrumentData(
        label:  'Lead',
        icon:   Icons.electric_bolt,
        color:  const Color(0xFFFFD600),
        value:  difficulty.guitar,
      ),
      _InstrumentData(
        label:  'Bass',
        icon:   Icons.queue_music,
        color:  const Color(0xFF40C4FF),
        value:  difficulty.bass,
      ),
      _InstrumentData(
        label:  'Drums',
        icon:   Icons.radio_button_checked,
        color:  const Color(0xFFFF5252),
        value:  difficulty.drums,
      ),
    ];

    // Nur Instrumente anzeigen die verfügbar sind (value > 0)
    final available = instruments.where((i) => i.value > 0).toList();

    if (available.isEmpty) {
      return Text(
        'Keine Daten verfügbar',
        style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 13),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        children: available.map((inst) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                // Instrument-Icon
                Icon(inst.icon, color: inst.color, size: 18),
                const SizedBox(width: 8),
                // Label
                SizedBox(
                  width: 52,
                  child: Text(
                    inst.label,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.70),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Striche (Balken 1–7)
                Expanded(
                  child: Row(
                    children: List.generate(7, (i) {
                      final filled = i < inst.value;
                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          height: 14,
                          decoration: BoxDecoration(
                            color: filled
                                ? inst.color
                                : inst.color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(width: 8),
                // Zahl
                Text(
                  '${inst.value}/7',
                  style: TextStyle(
                    color: inst.color.withOpacity(0.90),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _InstrumentData {
  final String   label;
  final IconData icon;
  final Color    color;
  final int      value;

  const _InstrumentData({
    required this.label,
    required this.icon,
    required this.color,
    required this.value,
  });
}

// ─────────────────────────────────────────────────────────
// Kleine Hilfs-Widgets
// ─────────────────────────────────────────────────────────

class _AlbumCover extends StatelessWidget {
  final String? url;
  final bool    loading;

  const _AlbumCover({required this.url, required this.loading});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withOpacity(0.07),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: loading
            ? const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Color(0xFF9C6FFF)),
                ),
              )
            : (url != null && url!.isNotEmpty)
                ? Image.network(
                    url!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholder(),
                  )
                : _placeholder(),
      ),
    );
  }

  Widget _placeholder() => Icon(
        Icons.music_note,
        color: Colors.white.withOpacity(0.30),
        size: 32,
      );
}

class _DifficultyLoading extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
        children: [
          const SizedBox(
            width: 16, height: 16,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: Color(0xFF9C6FFF)),
          ),
          const SizedBox(width: 10),
          Text('Lade Schwierigkeitsdaten…',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.45), fontSize: 13)),
        ],
      );
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String   label;
  final bool     active;
  final Color    color;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.active,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color:  active ? color.withOpacity(0.18) : Colors.white.withOpacity(0.07),
            border: Border.all(
                color: active ? color.withOpacity(0.55) : Colors.white.withOpacity(0.12)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: active ? color : Colors.white.withOpacity(0.60)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: active ? color : Colors.white.withOpacity(0.70),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      );
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: TextStyle(
          color: Colors.white.withOpacity(0.40),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      );
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 88,
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.45),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        height: 1,
        color: Colors.white.withOpacity(0.08),
      );
}
