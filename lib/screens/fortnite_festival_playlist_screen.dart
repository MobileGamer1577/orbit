import 'package:flutter/material.dart';

import '../storage/collection_store.dart';
import '../theme/orbit_theme.dart';

class FortniteFestivalPlaylistScreen extends StatelessWidget {
  final CollectionStore collection;

  const FortniteFestivalPlaylistScreen({super.key, required this.collection});

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
                        'Playlist',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                OrbitGlassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Kommt bald ✅\n\nGeplant:\n• Playlist aus Weekly Rotation\n• Playlist aus deinen Owned-Songs\n• Playlist aus ALLEN Songs\n\n(Tipp: Owned/Wishlist kannst du schon in der Song-Suche setzen.)',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.75),
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
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
