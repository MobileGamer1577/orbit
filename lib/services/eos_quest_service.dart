import 'dart:convert';
import 'dart:developer' as dev;
import 'package:http/http.dart' as http;
import '../storage/account_store.dart';

// ══════════════════════════════════════════════════════════════
//
//  🌐 EOS QUEST SERVICE
//  Datei: lib/services/eos_quest_service.dart
//
//  Flow:
//    1. Epic Access Token aus AccountStore holen
//    2. POST api.epicgames.dev/auth/v1/oauth/token
//       → EOS Connect Token holen
//    3. GET fngw-svc-ds-livefn.ol.epicgames.com/api/quest/v3/
//         {deploymentId}/progress/account/{accountId}
//       → Quest-Daten holen
//
// ══════════════════════════════════════════════════════════════

// Fortnite Live Client-Credentials (aus dem Spiel selbst, öffentlich bekannt)
const _kClientId     = 'ec684b8c687f479fadea3cb2ad83f5c6';
const _kClientSecret = 'e1f31c211f284131862627d37a13fc84d';
const _kDeploymentId = '62a9473a2dca46b29ccf17577fcf42d7';

const _kEosAuthUrl   = 'https://api.epicgames.dev/auth/v1/oauth/token';
const _kQuestBaseUrl =
    'https://fngw-svc-ds-livefn.ol.epicgames.com/api/quest/v3';

const Duration _timeout = Duration(seconds: 25);

// ──────────────────────────────────────────────────────────────
//  Result-Klassen
// ──────────────────────────────────────────────────────────────

class EosQuestResult {
  final bool        success;
  final String?     error;
  final List<EosQuest> quests;
  final Map<String, dynamic>? rawResponse; // für Debugging

  const EosQuestResult({
    required this.success,
    this.error,
    this.quests = const [],
    this.rawResponse,
  });

  factory EosQuestResult.err(String msg) =>
      EosQuestResult(success: false, error: msg);
}

class EosQuest {
  final String   templateId;
  final String   state;      // 'Active', 'Claimed', etc.
  final List<EosObjective> objectives;
  final String   challengeBundleId;

  /// Anzeige-Name aus templateId extrahiert (best-effort)
  String get displayName {
    // z.B. "Quest:sparksquest_s09_prestige_ms_02b" → "sparksquest s09 prestige ms 02b"
    final raw = templateId.contains(':')
        ? templateId.split(':').last
        : templateId;
    return raw.replaceAll('_', ' ');
  }

  const EosQuest({
    required this.templateId,
    required this.state,
    required this.objectives,
    required this.challengeBundleId,
  });

  factory EosQuest.fromJson(Map<String, dynamic> j) {
    final rawObjectives = j['objectives'] as List? ?? [];
    return EosQuest(
      templateId:        (j['templateId'] as String?) ?? '',
      state:             (j['state']      as String?) ?? '',
      challengeBundleId: (j['challengeBundleId'] as String?) ?? '',
      objectives:        rawObjectives
          .whereType<Map<String, dynamic>>()
          .map(EosObjective.fromJson)
          .toList(),
    );
  }
}

class EosObjective {
  final String statName;
  final int    quantity;
  final int    stage;

  const EosObjective({
    required this.statName,
    required this.quantity,
    required this.stage,
  });

  factory EosObjective.fromJson(Map<String, dynamic> j) => EosObjective(
    statName: (j['statName'] as String?) ?? '',
    quantity: (j['quantity'] as int?)    ?? 0,
    stage:    (j['stage']    as int?)    ?? -1,
  );
}

// ──────────────────────────────────────────────────────────────
//  Service
// ──────────────────────────────────────────────────────────────

class EosQuestService {
  static final EosQuestService instance = EosQuestService._();
  EosQuestService._();

  // ──────────────────────────────────────────────────────────
  //  SCHRITT 1: EOS Connect Token holen
  // ──────────────────────────────────────────────────────────

  Future<String?> _getEosToken(String epicToken) async {
    dev.log('🔑 EOS: Token-Austausch…', name: 'OrbitEOS');

    // Basic Auth: base64(clientId:clientSecret)
    final credentials = base64Encode(
        utf8.encode('$_kClientId:$_kClientSecret'));

    try {
      final res = await http
          .post(
            Uri.parse(_kEosAuthUrl),
            headers: {
              'Authorization':  'Basic $credentials',
              'Content-Type':   'application/x-www-form-urlencoded',
              'Accept':         'application/json',
            },
            body: {
              'grant_type':          'external_auth',
              'external_auth_type':  'epicgames_access_token',
              'external_auth_token': epicToken,
              'deployment_id':       _kDeploymentId,
              'nonce':               'orbit_${DateTime.now().millisecondsSinceEpoch}',
            },
          )
          .timeout(_timeout);

      dev.log(
        'EOS Auth → HTTP ${res.statusCode}\n'
        '${res.body.length > 500 ? res.body.substring(0, 500) : res.body}',
        name: 'OrbitEOS',
      );

      if (res.statusCode != 200) {
        dev.log('❌ EOS Auth Fehler: HTTP ${res.statusCode}', name: 'OrbitEOS');
        return null;
      }

      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final token = json['access_token'] as String?;
      if (token != null) {
        dev.log('✅ EOS Token erhalten', name: 'OrbitEOS');
      }
      return token;
    } catch (e) {
      dev.log('❌ _getEosToken Fehler: $e', name: 'OrbitEOS');
      return null;
    }
  }

  // ──────────────────────────────────────────────────────────
  //  SCHRITT 2: Quests laden
  // ──────────────────────────────────────────────────────────

  Future<EosQuestResult> fetchQuests() async {
    // Account prüfen
    final epicToken = AccountStore.fortniteToken;
    final accountId = AccountStore.fortniteAccountId;

    if (epicToken == null || epicToken.isEmpty) {
      return EosQuestResult.err('no_account');
    }
    if (accountId == null || accountId.isEmpty) {
      return EosQuestResult.err('no_account');
    }

    dev.log(
      '📡 EOS Quests für accountId=$accountId',
      name: 'OrbitEOS',
    );

    // EOS Token holen
    final eosToken = await _getEosToken(epicToken);
    if (eosToken == null) {
      return EosQuestResult.err(
        'EOS-Token konnte nicht geholt werden.\n'
        'Möglicherweise ist der Epic-Token abgelaufen → '
        'bitte Account neu verbinden.',
      );
    }

    // Quest-Endpunkt aufrufen
    final url = '$_kQuestBaseUrl/$_kDeploymentId/progress/account/$accountId';
    dev.log('📡 GET $url', name: 'OrbitEOS');

    try {
      final res = await http
          .get(
            Uri.parse(url),
            headers: {
              'Authorization': 'Bearer $eosToken',
              'Accept':        'application/json',
            },
          )
          .timeout(_timeout);

      dev.log(
        'EOS Quests → HTTP ${res.statusCode}\n'
        '${res.body.length > 1000 ? res.body.substring(0, 1000) + "…" : res.body}',
        name: 'OrbitEOS',
      );

      if (res.statusCode == 401) {
        return EosQuestResult.err(
          'Zugriff verweigert (401).\n'
          'Epic-Token ist möglicherweise abgelaufen.',
        );
      }
      if (res.statusCode != 200) {
        return EosQuestResult.err('HTTP ${res.statusCode}: ${res.body}');
      }

      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final questProgress = json['questProgress'] as Map<String, dynamic>?;
      final rawQuests     = questProgress?['quests'] as List? ?? [];

      final quests = rawQuests
          .whereType<Map<String, dynamic>>()
          .map(EosQuest.fromJson)
          .toList();

      dev.log('✅ ${quests.length} Quests geladen', name: 'OrbitEOS');

      return EosQuestResult(
        success:     true,
        quests:      quests,
        rawResponse: json,
      );
    } catch (e) {
      return EosQuestResult.err('Netzwerkfehler: $e');
    }
  }
}
