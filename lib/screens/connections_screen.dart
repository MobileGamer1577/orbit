import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/fortnite_oauth_service.dart';
import '../storage/account_store.dart';
import '../theme/orbit_theme.dart';
import '../widgets/orbit_glass_card.dart';

// ══════════════════════════════════════════════════════════════
//
//  🔗 CONNECTIONS SCREEN
//  Datei: lib/screens/connections_screen.dart
//
//  ── LOGIN-FLOW (Device Code Flow) ────────────────────────
//
//  1. "Mit Fortnite verbinden" drücken
//     → App ruft GET /api/v1/oauth/get-token ab
//     → Bekommt flowId + Login-URL zurück
//
//  2. Login-URL öffnet sich im Browser
//     → Nutzer meldet sich mit Epic-Account an
//     → Kein Code-Kopieren nötig!
//
//  3. App pollt automatisch alle 3 Sekunden im Hintergrund
//     → POST /api/v1/oauth/complete { flowId }
//     → Wenn Nutzer angemeldet ist: Token direkt gespeichert
//
//  ── RE-LOGIN (automatisch, kein Browser) ─────────────────
//
//  Die App speichert deviceId + secret nach dem ersten Login.
//  Damit kann sie den Token im Hintergrund erneuern ohne dass
//  der Nutzer irgendetwas tun muss.
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
//  FORTNITE CARD — Device Code Flow mit Auto-Polling
// ══════════════════════════════════════════════════════════════

class _FortniteCard extends StatefulWidget {
  final VoidCallback onChanged;
  const _FortniteCard({required this.onChanged});

  @override
  State<_FortniteCard> createState() => _FortniteCardState();
}

class _FortniteCardState extends State<_FortniteCard> {
  static const _accent = Color(0xFF00D4FF);

  // Status: 'idle' | 'starting' | 'waiting' | 'done'
  String _step = 'idle';
  String? _errorMsg;
  String? _flowId;
  String? _loginUrl;

  Timer? _pollTimer;
  int _pollCount = 0;
  static const int _maxPolls = 120; // 120 × 3s = 6 Minuten Timeout

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  // ── LOGIN STARTEN ─────────────────────────────────────────

  Future<void> _startLogin() async {
    setState(() {
      _step = 'starting';
      _errorMsg = null;
    });

    final flow = await FortniteOAuthService.instance.startDeviceFlow();

    if (!mounted) return;

    if (flow == null || flow.hasError) {
      setState(() {
        _step = 'idle';
        _errorMsg = flow?.errorDetails ?? 'Verbindung zur API fehlgeschlagen.';
      });
      return;
    }

    _flowId = flow.flowId;
    _loginUrl = flow.url;

    // Browser öffnen
    try {
      await launchUrl(
        Uri.parse(flow.url!),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {}

    setState(() {
      _step = 'waiting';
      _pollCount = 0;
    });
    _startPolling();
  }

  // ── AUTO-POLLING ─────────────────────────────────────────

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (!mounted) {
        _pollTimer?.cancel();
        return;
      }

      _pollCount++;
      if (_pollCount > _maxPolls) {
        _pollTimer?.cancel();
        if (mounted) {
          setState(() {
            _step = 'idle';
            _errorMsg = 'Zeitüberschreitung. Bitte erneut versuchen.';
            _flowId = null;
            _loginUrl = null;
          });
        }
        return;
      }

      final r = await FortniteOAuthService.instance.pollCompletion(_flowId!);

      if (!mounted) return;

      if (r.isPending) return; // Weiter warten

      _pollTimer?.cancel();

      if (r.isError) {
        setState(() {
          _step = 'idle';
          _errorMsg = r.errorMessage ?? 'Unbekannter Fehler';
          _flowId = null;
        });
        return;
      }

      // ✅ Erfolgreich eingeloggt!
      final result = r.result!;
      final accountId = result.accountId ?? 'unknown';
      final displayName = result.displayName ?? 'Fortnite-Account';

      await AccountStore.saveFortnite(
        accountId: accountId,
        displayName: displayName,
        token: result.token!,
        tokenExpiry: result.tokenExpiry,
        deviceId: result.deviceId,
        deviceSecret: result.deviceSecret,
      );

      setState(() {
        _step = 'done';
      });
      widget.onChanged();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Mit $displayName verbunden!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  // ── POLLING ABBRECHEN ────────────────────────────────────

  void _cancelLogin() {
    _pollTimer?.cancel();
    setState(() {
      _step = 'idle';
      _errorMsg = null;
      _flowId = null;
      _loginUrl = null;
    });
  }

  // ── BROWSER NOCHMAL ÖFFNEN ───────────────────────────────

  Future<void> _reopenBrowser() async {
    if (_loginUrl == null) return;
    try {
      await launchUrl(
        Uri.parse(_loginUrl!),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {}
  }

  // ── VERBINDUNG TRENNEN ───────────────────────────────────

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
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Trennen'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await AccountStore.clearFortnite();
    setState(() {
      _step = 'idle';
      _errorMsg = null;
    });
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

          // ── Login-Inhalt (nur wenn nicht verbunden) ───────
          if (!isConnected) ...[
            Container(
              height: 1,
              color: Colors.white.withOpacity(0.07),
              margin: const EdgeInsets.symmetric(horizontal: 16),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _buildLoginContent(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoginContent() {
    switch (_step) {
      // ── Idle: Start-Button ─────────────────────────────
      case 'idle':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoBox(
              text:
                  'Du wirst zur Epic Games Anmeldeseite weitergeleitet. '
                  'Melde dich dort an — die App erkennt es automatisch.',
            ),
            const SizedBox(height: 12),
            if (_errorMsg != null) ...[
              _ErrorText(_errorMsg!),
              const SizedBox(height: 10),
            ],
            _BigButton(
              label: 'Mit Fortnite verbinden',
              icon: Icons.open_in_browser,
              color: _accent,
              onTap: _startLogin,
            ),
          ],
        );

      // ── Starting: Lädt ─────────────────────────────────
      case 'starting':
        return _CenteredLoader(label: 'Verbindung wird hergestellt…');

      // ── Waiting: Pollt ─────────────────────────────────
      case 'waiting':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _WaitingBox(onReopen: _reopenBrowser),
            const SizedBox(height: 14),
            _PollIndicator(pollCount: _pollCount, maxPolls: _maxPolls),
            const SizedBox(height: 14),
            Center(
              child: TextButton(
                onPressed: _cancelLogin,
                child: Text(
                  'Abbrechen',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.40),
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }
}

// ══════════════════════════════════════════════════════════════
//  KLEINE HILFS-WIDGETS
// ══════════════════════════════════════════════════════════════

class _InfoBox extends StatelessWidget {
  final String text;
  const _InfoBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF00D4FF).withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF00D4FF).withOpacity(0.20)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF00D4FF), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withOpacity(0.70),
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

class _WaitingBox extends StatelessWidget {
  final VoidCallback onReopen;
  const _WaitingBox({required this.onReopen});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.open_in_browser,
                color: Colors.greenAccent,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Browser geöffnet',
                style: TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Melde dich im Browser mit deinem Epic-Account an.\n'
            'Die App erkennt es automatisch — du musst nichts eingeben.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.65),
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: onReopen,
            child: Text(
              'Browser nicht geöffnet? Hier tippen.',
              style: TextStyle(
                color: const Color(0xFF00D4FF).withOpacity(0.80),
                fontSize: 12,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PollIndicator extends StatelessWidget {
  final int pollCount;
  final int maxPolls;
  const _PollIndicator({required this.pollCount, required this.maxPolls});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFF00D4FF),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'Warte auf Anmeldung im Browser…',
          style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 13),
        ),
      ],
    );
  }
}

class _CenteredLoader extends StatelessWidget {
  final String label;
  const _CenteredLoader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF00D4FF),
            ),
            const SizedBox(height: 12),
            Text(label, style: TextStyle(color: Colors.white54, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _ErrorText extends StatelessWidget {
  final String msg;
  const _ErrorText(this.msg);

  @override
  Widget build(BuildContext context) {
    return Text(
      msg,
      style: const TextStyle(
        color: Colors.redAccent,
        fontSize: 13,
        fontWeight: FontWeight.w500,
        height: 1.4,
      ),
    );
  }
}

class _BigButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _BigButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: color.withOpacity(0.80),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        ),
      ),
    );
  }
}

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
                  color: iconColor.withOpacity(0.15),
                  width: 1.2,
                ),
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
