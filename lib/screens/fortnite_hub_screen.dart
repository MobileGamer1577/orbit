import 'package:flutter/material.dart';

import '../storage/app_settings_store.dart';
import '../storage/collection_store.dart';
import '../theme/orbit_theme.dart';
import 'fortnite_countdown_screen.dart';
import 'fortnite_festival_hub_screen.dart';
import 'fortnite_locker_screen.dart';
import 'task_list_screen.dart';

class FortniteHubScreen extends StatelessWidget {
  final AppSettingsStore settings;
  final CollectionStore collection;

  const FortniteHubScreen({
    super.key,
    required this.settings,
    required this.collection,
  });

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
                        'Fortnite',
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
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _HubCard(
                        icon: Icons.timer,
                        title: 'Countdowns',
                        subtitle: 'Season Countdowns (bald)',
                        onTap: () => _push(
                          context,
                          FortniteCountdownScreen(settings: settings),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _HubCard(
                        icon: Icons.checklist,
                        title: 'Aufträge (bald)',
                        subtitle: 'BR, Reload, Ballistic, LEGO, OG…',
                        onTap: () => _push(
                          context,
                          const TaskListScreen(title: 'Aufträge'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _HubCard(
                        icon: Icons.storefront,
                        title: 'Item-Shop',
                        subtitle: 'Kommt bald',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Item-Shop kommt bald ✅'),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _HubCard(
                        icon: Icons.insights,
                        title: 'Stats',
                        subtitle: 'Kommt bald',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Stats kommen bald ✅'),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),

                      // NEW: Locker / Spind (keine 20 Karten)
                      _HubCard(
                        icon: Icons.inventory_2,
                        title: 'Spind',
                        subtitle: 'Alle Cosmetics (aktuell: Songs)',
                        onTap: () => _push(
                          context,
                          FortniteLockerScreen(collection: collection),
                        ),
                      ),

                      const SizedBox(height: 12),
                      _HubCard(
                        icon: Icons.music_note,
                        title: 'Festival',
                        subtitle: 'Songs suchen & Playlist bauen',
                        onTap: () => _push(
                          context,
                          FortniteFestivalHubScreen(collection: collection),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _HubCard(
                        icon: Icons.public,
                        title: 'Status',
                        subtitle: 'Kommt bald (Server/Services)',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Status kommt bald ✅'),
                            ),
                          );
                        },
                      ),
                    ],
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
