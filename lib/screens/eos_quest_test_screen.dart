import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/eos_quest_service.dart';
import '../storage/account_store.dart';
import '../theme/orbit_theme.dart';
import '../widgets/orbit_glass_card.dart';
import 'connections_screen.dart';

// ══════════════════════════════════════════════════════════════
//
//  🧪 EOS QUEST TEST SCREEN
//  Datei: lib/screens/eos_quest_test_screen.dart
//
//  Testet die neue EOS Quest API:
//    GET fngw-svc-ds-livefn.ol.epicgames.com/api/quest/v3/
//        {deploymentId}/progress/account/{accountId}
//
//  Zeigt:
//    • Verbindungs-Status
//    • Geladene Quests (templateId + state + objectives)
//    • Rohe API-Antwort (kopierbar für Debugging)
//
// ══════════════════════════════════════════════════════════════

class EosQuestTestScreen extends StatefulWidget {
  const EosQuestTestScreen({super.key});

  @override
  State<EosQuestTestScreen> createState() => _EosQuestTestScreenState();
}

class _EosQuestTestScreenState extends State<EosQuestTestScreen> {
  EosQuestResult? _result;
  bool            _loading = false;
  bool            _showRaw = false;

  @override
  void initState() {
    super.initState();
    // Automatisch laden wenn Account verbunden
    if (AccountStore.isFortniteConnected) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() { _loading = true; });
    final result = await EosQuestService.instance.fetchQuests();
    if (mounted) setState(() { _result = result; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = AccountStore.isFortniteConnected;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: OrbitBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ─────────────────────────────────
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
                            '🧪 EOS Quest API Test',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                          Text(
                            'EpicGames / FN-Service / EOS-Services / Quests',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white38,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isConnected && !_loading)
                      IconButton(
                        icon: Icon(
                          Icons.refresh,
                          color: Colors.white.withOpacity(0.70),
                        ),
                        onPressed: _load,
                      ),
                  ],
                ),
              ),

              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  children: [
                    // ── Account-Status ──────────────────
                    _StatusCard(isConnected: isConnected),
                    const SizedBox(height: 12),

                    // ── Kein Account ────────────────────
                    if (!isConnected)
                      _ConnectPrompt(
                        onConnected: () {
                          setState(() {});
                          if (AccountStore.isFortniteConnected) _load();
                        },
                      ),

                    // ── Laden ───────────────────────────
                    if (isConnected && _loading)
                      const _LoadingCard(),

                    // ── Ergebnis ────────────────────────
                    if (!_loading && _result != null) ...[
                      _ResultHeader(result: _result!),
                      const SizedBox(height: 12),

                      if (_result!.success) ...[
                        // Quest-Liste
                        ..._result!.quests.map((q) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _QuestCard(quest: q),
                        )),

                        const SizedBox(height: 16),

                        // Roh-Antwort togglen
                        GestureDetector(
                          onTap: () => setState(() => _showRaw = !_showRaw),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.10)),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _showRaw
                                      ? Icons.expand_less
                                      : Icons.expand_more,
                                  color: Colors.white54,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _showRaw
                                      ? 'Rohe Antwort verbergen'
                                      : 'Rohe API-Antwort anzeigen',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.55),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Spacer(),
                                GestureDetector(
                                  onTap: () {
                                    final raw = const JsonEncoder.withIndent('  ')
                                        .convert(_result!.rawResponse);
                                    Clipboard.setData(
                                        ClipboardData(text: raw));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('📋 In Zwischenablage kopiert'),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },
                                  child: const Icon(
                                    Icons.copy,
                                    color: Colors.white38,
                                    size: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        if (_showRaw) ...[
                          const SizedBox(height: 8),
                          _RawResponseCard(data: _result!.rawResponse),
                        ],
                      ],
                    ],
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
//  _StatusCard — Account-Verbindung
// ──────────────────────────────────────────────────────────────

class _StatusCard extends StatelessWidget {
  final bool isConnected;
  const _StatusCard({required this.isConnected});

  @override
  Widget build(BuildContext context) {
    final color = isConnected
        ? const Color(0xFF00E676)
        : Colors.orange;

    return OrbitGlassCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.6), blurRadius: 6),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isConnected ? 'Account verbunden' : 'Kein Account',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                if (isConnected)
                  Text(
                    AccountStore.fortniteDisplayName ?? '',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.55),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          // Endpoint Info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withOpacity(0.10)),
            ),
            child: const Text(
              'EOS v3',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  _ConnectPrompt
// ──────────────────────────────────────────────────────────────

class _ConnectPrompt extends StatelessWidget {
  final VoidCallback onConnected;
  const _ConnectPrompt({required this.onConnected});

  @override
  Widget build(BuildContext context) {
    return OrbitGlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(
            Icons.link_off,
            color: Colors.white.withOpacity(0.25),
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            'Für diesen Test musst du deinen '
            'Fortnite-Account verbinden.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.60),
              fontSize: 14,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const ConnectionsScreen()),
            ).then((_) => onConnected()),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF00D4FF).withOpacity(0.80),
            ),
            icon: const Icon(Icons.link, size: 16),
            label: const Text(
              'Account verbinden',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  _LoadingCard
// ──────────────────────────────────────────────────────────────

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return OrbitGlassCard(
      padding: const EdgeInsets.all(24),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Color(0xFF9C6FFF)),
          SizedBox(height: 14),
          Text(
            'EOS Token wird geholt…\ndann Quests laden…',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 13,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  _ResultHeader — Erfolg / Fehler
// ──────────────────────────────────────────────────────────────

class _ResultHeader extends StatelessWidget {
  final EosQuestResult result;
  const _ResultHeader({required this.result});

  @override
  Widget build(BuildContext context) {
    if (result.success) {
      return OrbitGlassCard(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF00E676), size: 20),
            const SizedBox(width: 10),
            Text(
              '${result.quests.length} Quests geladen ✅',
              style: const TextStyle(
                color: Color(0xFF00E676),
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.redAccent.withOpacity(0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              result.error ?? 'Unbekannter Fehler',
              style: const TextStyle(
                color: Colors.redAccent,
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
//  _QuestCard — einzelne Quest
// ──────────────────────────────────────────────────────────────

class _QuestCard extends StatelessWidget {
  final EosQuest quest;
  const _QuestCard({required this.quest});

  Color get _stateColor => switch (quest.state.toLowerCase()) {
    'claimed'   => const Color(0xFF00E676),
    'active'    => const Color(0xFF00D4FF),
    'completed' => const Color(0xFFFFD700),
    _           => Colors.white38,
  };

  @override
  Widget build(BuildContext context) {
    return OrbitGlassCard(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    quest.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _stateColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _stateColor.withOpacity(0.45)),
                  ),
                  child: Text(
                    quest.state,
                    style: TextStyle(
                      color: _stateColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            // Objectives
            if (quest.objectives.isNotEmpty) ...[
              const SizedBox(height: 6),
              ...quest.objectives.map((o) => Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  children: [
                    Icon(
                      Icons.circle,
                      size: 5,
                      color: Colors.white.withOpacity(0.30),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${o.statName}: ${o.quantity}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.45),
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  _RawResponseCard
// ──────────────────────────────────────────────────────────────

class _RawResponseCard extends StatelessWidget {
  final Map<String, dynamic>? data;
  const _RawResponseCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final pretty = const JsonEncoder.withIndent('  ').convert(data);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.40),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: SelectableText(
        pretty,
        style: const TextStyle(
          color: Color(0xFF9C6FFF),
          fontSize: 11,
          fontFamily: 'monospace',
          height: 1.5,
        ),
      ),
    );
  }
}
