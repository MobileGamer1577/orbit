import 'package:flutter/material.dart';

import '../services/fortnite_quest_api_service.dart';
import '../storage/account_store.dart';
import '../theme/orbit_theme.dart';
import '../widgets/orbit_glass_card.dart';

// ══════════════════════════════════════════════════════════════
//
//  🔗 CONNECTIONS SCREEN
//  Datei: lib/screens/connections_screen.dart
//
//  Erreichbar über: Einstellungen → Verbindungen
//
//  Zeigt alle Spiele die mit einem Account verbunden werden
//  können. Aktuell nur Fortnite; BO7 und andere kommen später.
//
//  ── WIE DIE FORTNITE-VERBINDUNG FUNKTIONIERT ─────────────
//
//  1. Nutzer gibt seinen Epic-Anzeigenamen (Gamertag) ein
//  2. App ruft api-fortnite.com an:
//       GET /api/v1/account/displayName/{name}
//  3. API gibt die Account-ID zurück
//  4. Account-ID wird lokal in Hive gespeichert (offline verfügbar)
//  5. Quest-Service nutzt diese ID für alle zukünftigen Anfragen
//
//  ── WO WIRD DAS GENUTZT? ─────────────────────────────────
//
//  AccountStore.fortniteAccountId
//    → fortnite_quest_api_service.dart → fetchQuests()
//
// ══════════════════════════════════════════════════════════════

class ConnectionsScreen extends StatefulWidget {
  const ConnectionsScreen({super.key});

  @override
  State<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends State<ConnectionsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: OrbitBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Header ─────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.arrow_back,
                        color: Colors.white.withOpacity(0.90),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Verbindungen',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                          Text(
                            'Verbinde deine Spiel-Accounts',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white54,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [

                    // ── Info-Box ─────────────────────────────
                    _InfoBox(),
                    const SizedBox(height: 16),

                    // ── Fortnite ─────────────────────────────
                    _FortniteConnectionCard(
                      onChanged: () => setState(() {}),
                    ),

                    const SizedBox(height: 12),

                    // ── BO7 (Zukunft) ─────────────────────────
                    _ComingSoonCard(
                      icon: Icons.military_tech,
                      iconColor: const Color(0xFFFF6B35),
                      title: 'Call of Duty: BO7',
                      subtitle: 'Account-Verbindung kommt bald',
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  Info-Box
// ──────────────────────────────────────────────────────────────

class _InfoBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF00D4FF).withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00D4FF).withOpacity(0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline,
              color: Color(0xFF00D4FF), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Verbinde deinen Account um Quests automatisch zu laden. '
              'Alle Daten werden nur lokal auf deinem Gerät gespeichert.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.75),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  Fortnite Connection Card
// ──────────────────────────────────────────────────────────────

class _FortniteConnectionCard extends StatefulWidget {
  final VoidCallback onChanged;
  const _FortniteConnectionCard({required this.onChanged});

  @override
  State<_FortniteConnectionCard> createState() =>
      _FortniteConnectionCardState();
}

class _FortniteConnectionCardState extends State<_FortniteConnectionCard> {
  static const _accent = Color(0xFF00D4FF);

  final _ctrl = TextEditingController();
  bool _expanded  = false;
  bool _loading   = false;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // Verbinden-Button getippt
  Future<void> _connect() async {
    final name = _ctrl.text.trim();
    if (name.isEmpty) return;

    setState(() { _loading = true; _error = null; });

    // Account-ID über API suchen
    final result = await FortniteQuestApiService.instance.lookupAccount(name);

    if (!mounted) return;

    if (result != null) {
      // Erfolgreich → Account lokal speichern
      await AccountStore.saveFortnite(
        accountId:   result.accountId,
        displayName: result.displayName,
      );
      _ctrl.clear();
      setState(() { _expanded = false; _loading = false; });
      widget.onChanged();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '✅ Mit ${result.displayName} verbunden!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      setState(() {
        _error   = 'Account nicht gefunden. Prüfe den Anzeigenamen.';
        _loading = false;
      });
    }
  }

  // Verbindung trennen
  Future<void> _disconnect() async {
    await AccountStore.clearFortnite();
    widget.onChanged();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = AccountStore.isFortniteConnected;
    final displayName = AccountStore.fortniteDisplayName;

    return OrbitGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Karten-Header ────────────────────────────────
          InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: isConnected ? null : () {
              setState(() { _expanded = !_expanded; _error = null; });
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
              child: Row(
                children: [
                  // Spiel-Icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _accent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: _accent.withOpacity(0.35), width: 1.2),
                    ),
                    child:
                        const Icon(Icons.bolt, color: _accent, size: 24),
                  ),
                  const SizedBox(width: 14),

                  // Text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Fortnite',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          isConnected
                              ? 'Verbunden als $displayName'
                              : 'Nicht verbunden',
                          style: TextStyle(
                            color: isConnected
                                ? const Color(0xFF00E676)
                                : Colors.white.withOpacity(0.50),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Status-Badge oder Chevron
                  if (isConnected)
                    _DisconnectBtn(onTap: _disconnect)
                  else
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Colors.white.withOpacity(0.40),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── Eingabe-Bereich (nur wenn nicht verbunden + expanded) ──
          if (!isConnected && _expanded) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 1,
                    color: Colors.white.withOpacity(0.07),
                    margin: const EdgeInsets.only(bottom: 14),
                  ),

                  // Hinweis wie man den Namen findet
                  Text(
                    'Gib deinen Epic-Anzeigenamen ein (z.B. MobileGamer1577)',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.55),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Eingabefeld
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _error != null
                            ? Colors.redAccent.withOpacity(0.60)
                            : Colors.white.withOpacity(0.14),
                      ),
                    ),
                    child: TextField(
                      controller: _ctrl,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'Epic-Anzeigenamen eingeben…',
                        hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.35),
                          fontSize: 15,
                        ),
                        prefixIcon: Icon(Icons.person_outline,
                            color: Colors.white.withOpacity(0.45)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 14),
                      ),
                      onSubmitted: (_) => _connect(),
                      textInputAction: TextInputAction.done,
                    ),
                  ),

                  // Fehlertext
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Verbinden-Button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _loading ? null : _connect,
                      style: FilledButton.styleFrom(
                        backgroundColor: _accent.withOpacity(0.80),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ))
                          : const Text(
                              'Verbinden',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Wo finde ich meinen Namen?
                  Center(
                    child: Text(
                      'Wo finde ich meinen Anzeigenamen?\n'
                      'Epic Games → Konto → Allgemeine Informationen',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.35),
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  Verbindung-Trennen Button
// ──────────────────────────────────────────────────────────────

class _DisconnectBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _DisconnectBtn({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final ok = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: const Color(0xFF1A1026),
            title: const Text(
              'Verbindung trennen?',
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              'Die Fortnite-Verbindung wird getrennt. '
              'Gespeicherte Quest-Fortschritte bleiben erhalten.',
              style: TextStyle(color: Colors.white.withOpacity(0.70)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Abbrechen'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Trennen'),
              ),
            ],
          ),
        );
        if (ok == true) onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.red.withOpacity(0.35)),
        ),
        child: const Text(
          'Trennen',
          style: TextStyle(
            color: Colors.redAccent,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  Coming Soon Card (für BO7 etc.)
// ──────────────────────────────────────────────────────────────

class _ComingSoonCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _ComingSoonCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return OrbitGlassCard(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: iconColor.withOpacity(0.15), width: 1.2),
              ),
              child: Icon(icon, color: iconColor.withOpacity(0.40), size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.45),
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.30),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withOpacity(0.10)),
              ),
              child: Text(
                'Bald',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.30),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
