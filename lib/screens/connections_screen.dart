import 'package:flutter/material.dart';

import '../services/fortnite_oauth_service.dart';
import '../storage/account_store.dart';
import '../theme/orbit_theme.dart';
import '../widgets/orbit_glass_card.dart';
import 'fortnite_login_webview.dart';

// ══════════════════════════════════════════════════════════════
//
//  🔗 CONNECTIONS SCREEN
//  Datei: lib/screens/connections_screen.dart
//
//  ── LOGIN-FLOW ────────────────────────────────────────────
//
//  1. "Mit Fortnite verbinden" drücken
//     → URL wird direkt gebaut (kein API-Call, kein Pro-Plan nötig)
//
//  2. Epic-Login in In-App-WebView öffnen
//     → Nutzer meldet sich mit Epic-Account an
//     → WebView fängt ?code=... aus der Redirect-URL ab
//
//  3. POST /api/v1/oauth/link { "code": "..." }
//     → Token + DeviceAuth → lokal gespeichert
//     Fallback: POST /api/v1/oauth/exchange-code
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
              // ── Header ───────────────────────────────────
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
                    _FortniteCard(onChanged: () => setState(() {})),
                    const SizedBox(height: 12),
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

// ══════════════════════════════════════════════════════════════
//  FORTNITE CARD
// ══════════════════════════════════════════════════════════════

class _FortniteCard extends StatefulWidget {
  final VoidCallback onChanged;
  const _FortniteCard({required this.onChanged});

  @override
  State<_FortniteCard> createState() => _FortniteCardState();
}

class _FortniteCardState extends State<_FortniteCard> {
  static const _accent = Color(0xFF00D4FF);

  bool    _loading = false;
  String? _error;

  // ── LOGIN ─────────────────────────────────────────────────

  Future<void> _startLogin() async {
    setState(() { _loading = true; _error = null; });

    // URL direkt bauen — kein API-Call, kein Pro-Plan nötig
    final loginUrl = FortniteOAuthService.instance.buildAuthorizeUrl();

    setState(() => _loading = false);

    // WebView öffnen → Code abfangen
    final code = await Navigator.push<String?>(
      context,
      MaterialPageRoute(
        builder: (_) => FortniteLoginWebView(loginUrl: loginUrl),
      ),
    );

    if (!mounted || code == null) return; // Abgebrochen

    setState(() { _loading = true; _error = null; });

    // Code gegen Token tauschen
    final result = await FortniteOAuthService.instance.linkWithCode(code);

    if (!mounted) return;

    if (result == null || result.token == null) {
      setState(() {
        _loading = false;
        _error   = 'Anmeldung fehlgeschlagen.\nBitte versuche es erneut.';
      });
      return;
    }

    // Speichern
    await AccountStore.saveFortnite(
      accountId:    result.accountId    ?? 'unknown',
      displayName:  result.displayName  ?? 'Fortnite-Account',
      token:        result.token!,
      tokenExpiry:  result.tokenExpiry,
      deviceId:     result.deviceId,
      deviceSecret: result.deviceSecret,
    );

    if (!mounted) return;
    setState(() => _loading = false);
    widget.onChanged();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '✅ Mit ${result.displayName ?? "Fortnite"} verbunden!',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── DISCONNECT ────────────────────────────────────────────

  Future<void> _disconnect() async {
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
    if (ok != true) return;
    await AccountStore.clearFortnite();
    setState(() { _error = null; });
    widget.onChanged();
  }

  // ── BUILD ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isConnected = AccountStore.isFortniteConnected;
    final displayName = AccountStore.fortniteDisplayName;

    return OrbitGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Karten-Header ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _accent.withOpacity(0.35),
                      width: 1.2,
                    ),
                  ),
                  child: const Icon(Icons.bolt, color: _accent, size: 24),
                ),
                const SizedBox(width: 14),
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
                if (isConnected) _DisconnectBtn(onTap: _disconnect),
              ],
            ),
          ),

          // ── Login-Bereich (nur wenn nicht verbunden) ──────
          if (!isConnected) ...[
            Container(
              height: 1,
              color: Colors.white.withOpacity(0.07),
              margin: const EdgeInsets.symmetric(horizontal: 16),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: _loading
                  ? _LoadingView()
                  : _LoginView(
                      error:     _error,
                      onConnect: _startLogin,
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  Login-Ansicht
// ──────────────────────────────────────────────────────────────

class _LoginView extends StatelessWidget {
  final String?      error;
  final VoidCallback onConnect;

  const _LoginView({required this.error, required this.onConnect});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Info-Box
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF00D4FF).withOpacity(0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF00D4FF).withOpacity(0.20),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline,
                color: Color(0xFF00D4FF),
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Du wirst zur Epic Games Anmeldeseite weitergeleitet. '
                  'Melde dich dort an — die App erkennt es automatisch.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.70),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Fehlermeldung
        if (error != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.redAccent.withOpacity(0.35),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.redAccent,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    error!,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 12),

        // Connect Button
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onConnect,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF00D4FF).withOpacity(0.80),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.login, size: 18),
            label: const Text(
              'Mit Fortnite verbinden',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  Lade-Ansicht
// ──────────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF00D4FF),
            ),
            SizedBox(height: 12),
            Text(
              'Verbindung wird hergestellt…',
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  Trennen-Button
// ──────────────────────────────────────────────────────────────

class _DisconnectBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _DisconnectBtn({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
//  "Kommt bald" Karte
// ──────────────────────────────────────────────────────────────

class _ComingSoonCard extends StatelessWidget {
  final IconData icon;
  final Color    iconColor;
  final String   title;
  final String   subtitle;

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
                  color: iconColor.withOpacity(0.15),
                  width: 1.2,
                ),
              ),
              child: Icon(
                icon,
                color: iconColor.withOpacity(0.40),
                size: 24,
              ),
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
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: Colors.white.withOpacity(0.10)),
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
