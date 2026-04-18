import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
//  Erreichbar über: Einstellungen → Verbindungen
//  Oder direkt aus ApiQuestListScreen wenn kein Account verbunden.
//
//  ── LOGIN-FLOW ────────────────────────────────────────────
//
//  1. "Mit Fortnite verbinden" drücken
//     → App holt die Epic-Login-URL von api-fortnite.com
//     → URL öffnet sich im Browser
//
//  2. Im Browser: Epic-Account-Daten eingeben → Anmelden
//     → Epic zeigt nach der Anmeldung einen Authorization Code
//
//  3. Zurück in der App: Code in das Feld einfügen → "Verbinden"
//     → App tauscht den Code gegen ein OAuth-Token
//     → Account-ID + Token werden lokal gespeichert
//
//  ── WARUM DIESER FLOW? ────────────────────────────────────
//
//  Der Quests-Endpunkt GET /api/v2/quests/{accountId} braucht
//  den Header "x-fortnite-token" — das ist ein nutzerspezifischer
//  OAuth-Token von Epic Games. Ohne echten Login kein Token.
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
                      icon: Icon(Icons.arrow_back,
                          color: Colors.white.withOpacity(0.90)),
                    ),
                    const SizedBox(width: 4),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Verbindungen',
                            style: TextStyle(
                              fontSize: 26, fontWeight: FontWeight.w900,
                              color: Colors.white, letterSpacing: -0.3,
                            ),
                          ),
                          Text(
                            'Verbinde deine Spiel-Accounts',
                            style: TextStyle(
                              fontSize: 13, color: Colors.white54,
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
//  FORTNITE CARD — mit OAuth-Login-Flow
// ══════════════════════════════════════════════════════════════

class _FortniteCard extends StatefulWidget {
  final VoidCallback onChanged;
  const _FortniteCard({required this.onChanged});

  @override
  State<_FortniteCard> createState() => _FortniteCardState();
}

class _FortniteCardState extends State<_FortniteCard> {
  static const _accent = Color(0xFF00D4FF);

  // Steps: 'idle' → 'step1_opening' → 'step2_code' → 'step3_connecting' → 'done'
  String _step = 'idle';
  String? _errorMsg;
  String? _loginUrl;

  final _codeCtrl = TextEditingController();

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  // ── SCHRITT 1: Login-URL holen + Browser öffnen ──────────
  Future<void> _startLogin() async {
    setState(() { _step = 'step1_opening'; _errorMsg = null; });

    final url = await FortniteOAuthService.instance.getAuthorizeUrl();

    if (!mounted) return;

    if (url == null) {
      setState(() {
        _step     = 'idle';
        _errorMsg = 'Verbindung zur API fehlgeschlagen. Prüfe deine Internetverbindung.';
      });
      return;
    }

    _loginUrl = url;

    // Browser öffnen
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Fallback: URL in Clipboard kopieren
      await Clipboard.setData(ClipboardData(text: url));
    }

    setState(() { _step = 'step2_code'; });
  }

  // ── SCHRITT 2: URL nochmal öffnen ────────────────────────
  Future<void> _reopenBrowser() async {
    if (_loginUrl == null) return;
    try {
      await launchUrl(Uri.parse(_loginUrl!),
          mode: LaunchMode.externalApplication);
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: _loginUrl!));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('URL in Zwischenablage kopiert'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  // ── SCHRITT 3: Code gegen Token tauschen ─────────────────
  Future<void> _exchangeCode() async {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) return;

    setState(() { _step = 'step3_connecting'; _errorMsg = null; });

    final result = await FortniteOAuthService.instance.exchangeCode(code);

    if (!mounted) return;

    if (result == null || !result.isSuccess) {
      setState(() {
        _step     = 'step2_code';
        _errorMsg = result?.errorMessage ??
            'Code ungültig oder abgelaufen. Starte den Login neu.';
      });
      return;
    }

    // Token + AccountId speichern
    final accountId   = result.accountId   ?? 'unknown';
    final displayName = result.displayName ?? 'Fortnite-Account';

    await AccountStore.saveFortnite(
      accountId:   accountId,
      displayName: displayName,
      token:       result.token!,
      tokenExpiry: result.tokenExpiry,
    );

    _codeCtrl.clear();
    setState(() { _step = 'done'; });
    widget.onChanged();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('✅ Mit $displayName verbunden!'),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  // ── Verbindung trennen ────────────────────────────────────
  Future<void> _disconnect() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1026),
        title: const Text('Verbindung trennen?',
            style: TextStyle(color: Colors.white)),
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
    setState(() { _step = 'idle'; _errorMsg = null; _codeCtrl.clear(); });
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = AccountStore.isFortniteConnected;
    final displayName = AccountStore.fortniteDisplayName;

    return OrbitGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Karten-Header ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
            child: Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: _accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _accent.withOpacity(0.35), width: 1.2),
                  ),
                  child: const Icon(Icons.bolt, color: _accent, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Fortnite',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800, fontSize: 17,
                          )),
                      const SizedBox(height: 3),
                      Text(
                        isConnected
                            ? 'Verbunden als $displayName'
                            : 'Nicht verbunden',
                        style: TextStyle(
                          color: isConnected
                              ? const Color(0xFF00E676)
                              : Colors.white.withOpacity(0.50),
                          fontSize: 13, fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isConnected)
                  _DisconnectBtn(onTap: _disconnect),
              ],
            ),
          ),

          // ── Login-Steps ────────────────────────────────────
          if (!isConnected) ...[
            Container(height: 1, color: Colors.white.withOpacity(0.07),
                margin: const EdgeInsets.symmetric(horizontal: 16)),
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

      // ── Idle: Start-Button ───────────────────────────────
      case 'idle':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoRow(
              icon: Icons.info_outline,
              text: 'Du wirst zur Epic Games Anmeldeseite weitergeleitet. '
                    'Melde dich dort an und kopiere danach den angezeigten Code.',
            ),
            const SizedBox(height: 14),
            if (_errorMsg != null) ...[
              _ErrorText(_errorMsg!),
              const SizedBox(height: 10),
            ],
            _BigButton(
              label: 'Mit Fortnite verbinden',
              icon: Icons.open_in_browser,
              color: const Color(0xFF00D4FF),
              onTap: _startLogin,
            ),
          ],
        );

      // ── Schritt 1: Browser wird geöffnet ────────────────
      case 'step1_opening':
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                CircularProgressIndicator(
                    strokeWidth: 2, color: Color(0xFF00D4FF)),
                SizedBox(height: 12),
                Text('Browser wird geöffnet…',
                    style: TextStyle(
                        color: Colors.white54, fontSize: 13)),
              ],
            ),
          ),
        );

      // ── Schritt 2: Code eingeben ─────────────────────────
      case 'step2_code':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Schritt-Anzeige
            _StepBadge(step: 1, label: 'Browser geöffnet ✓'),
            const SizedBox(height: 12),
            _StepBadge(step: 2, label: 'Code aus dem Browser kopieren'),
            const SizedBox(height: 14),
            _InfoRow(
              icon: Icons.content_paste,
              text: 'Kopiere den Authorization Code von der Seite '
                    'und füge ihn unten ein.',
            ),
            const SizedBox(height: 12),

            // Code-Eingabe
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _errorMsg != null
                      ? Colors.redAccent.withOpacity(0.60)
                      : Colors.white.withOpacity(0.14),
                ),
              ),
              child: TextField(
                controller: _codeCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 14,
                    fontFamily: 'monospace'),
                decoration: InputDecoration(
                  hintText: 'Authorization Code hier einfügen…',
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.30), fontSize: 13),
                  prefixIcon: Icon(Icons.vpn_key_outlined,
                      color: Colors.white.withOpacity(0.45)),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.content_paste,
                        color: Colors.white.withOpacity(0.45), size: 18),
                    onPressed: () async {
                      final data = await Clipboard.getData(Clipboard.kTextPlain);
                      if (data?.text != null) {
                        _codeCtrl.text = data!.text!;
                      }
                    },
                    tooltip: 'Einfügen',
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
                maxLines: 3,
                minLines: 1,
              ),
            ),

            if (_errorMsg != null) ...[
              const SizedBox(height: 8),
              _ErrorText(_errorMsg!),
            ],
            const SizedBox(height: 12),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _reopenBrowser,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                          color: Colors.white.withOpacity(0.20)),
                      foregroundColor: Colors.white70,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Browser',
                        style: TextStyle(fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: _BigButton(
                    label: 'Verbinden',
                    icon: Icons.link,
                    color: const Color(0xFF00D4FF),
                    onTap: _exchangeCode,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),
            Center(
              child: TextButton(
                onPressed: () => setState(() {
                  _step = 'idle'; _errorMsg = null; _codeCtrl.clear();
                }),
                child: Text('Abbrechen',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.40), fontSize: 12)),
              ),
            ),
          ],
        );

      // ── Schritt 3: Code wird getauscht ───────────────────
      case 'step3_connecting':
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                CircularProgressIndicator(
                    strokeWidth: 2, color: Color(0xFF00D4FF)),
                SizedBox(height: 12),
                Text('Account wird verbunden…',
                    style: TextStyle(color: Colors.white54, fontSize: 13)),
              ],
            ),
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }
}

// ══════════════════════════════════════════════════════════════
//  KLEINE HILFS-WIDGETS
// ══════════════════════════════════════════════════════════════

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

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
          Icon(icon, color: const Color(0xFF00D4FF), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.70),
                    fontSize: 13, height: 1.4)),
          ),
        ],
      ),
    );
  }
}

class _StepBadge extends StatelessWidget {
  final int step;
  final String label;
  const _StepBadge({required this.step, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 22, height: 22,
          decoration: BoxDecoration(
            color: const Color(0xFF00D4FF).withOpacity(0.20),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text('$step',
                style: const TextStyle(
                    color: Color(0xFF00D4FF),
                    fontSize: 11, fontWeight: FontWeight.w800)),
          ),
        ),
        const SizedBox(width: 8),
        Text(label,
            style: TextStyle(
                color: Colors.white.withOpacity(0.75),
                fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _ErrorText extends StatelessWidget {
  final String msg;
  const _ErrorText(this.msg);

  @override
  Widget build(BuildContext context) {
    return Text(msg,
        style: const TextStyle(
            color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w500));
  }
}

class _BigButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _BigButton({
    required this.label, required this.icon,
    required this.color, required this.onTap,
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: Icon(icon, size: 18),
        label: Text(label,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
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
        child: const Text('Trennen',
            style: TextStyle(
                color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w700)),
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
    required this.icon, required this.iconColor,
    required this.title, required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return OrbitGlassCard(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: iconColor.withOpacity(0.15), width: 1.2),
              ),
              child: Icon(icon, color: iconColor.withOpacity(0.40), size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.45),
                          fontWeight: FontWeight.w800, fontSize: 17)),
                  const SizedBox(height: 3),
                  Text(subtitle,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.30), fontSize: 13)),
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
              child: Text('Bald',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.30),
                      fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}
