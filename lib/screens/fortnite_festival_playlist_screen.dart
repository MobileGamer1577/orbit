import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../widgets/orbit_glass_card.dart';
import '../storage/collection_store.dart';
import '../theme/orbit_theme.dart';

class FortniteFestivalPlaylistScreen extends StatelessWidget {
  final CollectionStore collection;

  const FortniteFestivalPlaylistScreen({super.key, required this.collection});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

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
                    Expanded(
                      child: Text(
                        l10n.festivalPlaylistTitle,
                        style: const TextStyle(
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
                      l10n.festivalPlaylistBody,
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
