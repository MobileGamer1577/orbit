import 'package:flutter/material.dart';

import '../storage/collection_store.dart';

class FestivalSongDetails {
  final String title;
  final String artist;
  final String songId; // e.g. SID_Placeholder_123
  final String source; // pass / shop / etc.
  final String bpm;
  final String released;
  final bool hasVocalPro;

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

    return FestivalSongDetails(
      title: pick('title'),
      artist: pick('artist'),
      songId: pick('songId'),
      source: pick('source'),
      bpm: pick('bpm'),
      released: pick('released'),
      hasVocalPro: pickBool('vocalPro'),
    );
  }
}

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

class _FestivalSongSheet extends StatelessWidget {
  final FestivalSongDetails song;
  final CollectionStore collection;

  const _FestivalSongSheet({required this.song, required this.collection});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(22);
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedBuilder(
      animation: collection,
      builder: (context, _) {
        final owned = collection.isOwned(
          CollectionStore.categoryFestivalSong,
          song.songId,
        );
        final wished = collection.isWished(
          CollectionStore.categoryFestivalSong,
          song.songId,
        );

        return Padding(
          padding: EdgeInsets.only(left: 12, right: 12, bottom: 12 + bottom),
          child: ClipRRect(
            borderRadius: radius,
            child: Material(
              color: const Color(0xFF1A1026).withOpacity(0.92),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                song.title.isEmpty
                                    ? 'Unbekannter Song'
                                    : song.title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                song.artist.isEmpty
                                    ? 'Unbekannter Artist'
                                    : song.artist,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.72),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            Icons.close,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _chip(
                          icon: owned
                              ? Icons.check_circle
                              : Icons.check_circle_outline,
                          label: owned ? 'Im Besitz' : 'Nicht im Besitz',
                          onTap: () => collection.toggleOwned(
                            CollectionStore.categoryFestivalSong,
                            song.songId,
                          ),
                        ),
                        _chip(
                          icon: wished ? Icons.favorite : Icons.favorite_border,
                          label: wished ? 'Wunschliste' : 'Zur Wunschliste',
                          onTap: () => collection.toggleWished(
                            CollectionStore.categoryFestivalSong,
                            song.songId,
                          ),
                        ),
                        _miniInfoChip(
                          icon: Icons.music_note,
                          label: song.bpm.isEmpty
                              ? 'BPM: ?'
                              : 'BPM: ${song.bpm}',
                        ),
                        _miniInfoChip(
                          icon: Icons.event,
                          label: song.released.isEmpty
                              ? 'Release: ?'
                              : 'Release: ${song.released}',
                        ),
                        _miniInfoChip(
                          icon: Icons.mic,
                          label: song.hasVocalPro
                              ? 'Vocal Pro: Ja'
                              : 'Vocal Pro: Nein',
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _kv('Song ID', song.songId.isEmpty ? '—' : song.songId),
                    _kv('Quelle', song.source.isEmpty ? '—' : song.source),
                    const SizedBox(height: 10),
                    Text(
                      'Später: Wenn wir eine Item-Shop API haben, kann Orbit dir Notifications geben, wenn ein Song aus deiner Wunschliste im Shop ist.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.55),
                        fontSize: 12,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static Widget _chip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: Colors.white.withOpacity(0.08),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: Colors.white.withOpacity(0.92)),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _miniInfoChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withOpacity(0.05),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white.withOpacity(0.72)),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              k,
              style: TextStyle(
                color: Colors.white.withOpacity(0.55),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              v,
              style: TextStyle(
                color: Colors.white.withOpacity(0.86),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
