import 'package:flutter/material.dart';

import '../storage/collection_store.dart';
import '../theme/orbit_theme.dart';
import 'fortnite_festival_playlist_screen.dart';
import 'fortnite_festival_search_screen.dart';

class FortniteFestivalHubScreen extends StatelessWidget {
  final CollectionStore collection;

  const FortniteFestivalHubScreen({super.key, required this.collection});

  void _push(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
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
                        'Festival',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Was willst du öffnen?',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.65),
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 14),
                _HubCard(
                  icon: Icons.search,
                  title: 'Songs suchen',
                  subtitle: 'Nach Song / Artist / Song-ID suchen',
                  onTap: () => _push(
                    context,
                    FortniteFestivalSearchScreen(collection: collection),
                  ),
                ),
                const SizedBox(height: 12),
                _HubCard(
                  icon: Icons.queue_music,
                  title: 'Playlist erstellen',
                  subtitle: 'Rotation • Besitz • Alle Songs (bald mehr)',
                  onTap: () => _push(
                    context,
                    FortniteFestivalPlaylistScreen(collection: collection),
                  ),
                ),
                const SizedBox(height: 12),
                OrbitGlassCard(
                  child: ListTile(
                    leading: Icon(
                      Icons.notifications,
                      color: Colors.white.withOpacity(0.85),
                    ),
                    title: const Text(
                      'Wishlist-Benachrichtigungen',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    subtitle: Text(
                      'Kommt später, sobald wir eine Shop-API haben',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: Colors.white.withOpacity(0.7),
                    ),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Kommt bald ✅')),
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

class _HubCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _HubCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OrbitGlassCard(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: Icon(icon, color: Colors.white.withOpacity(0.92)),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: Colors.white.withOpacity(0.7),
        ),
        onTap: onTap,
      ),
    );
  }
}
