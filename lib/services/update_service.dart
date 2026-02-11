import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class UpdateResult {
  final bool updateAvailable;
  final String current; // z.B. 0.1.0-beta+1
  final String latest;  // z.B. 0.1.1-beta+2
  final String? notes;
  final String? url; // download oder release url

  UpdateResult({
    required this.updateAvailable,
    required this.current,
    required this.latest,
    this.notes,
    this.url,
  });
}

class UpdateService {
  /// ✅ Orbit Update JSON (RAW)
  /// Datei kommt ins Repo: /update/orbit.json
  static const String updateJsonUrl =
  'https://raw.githubusercontent.com/MobileGamer1577/orbit/main/update/orbit.json';

  static Future<UpdateResult> checkForUpdates() async {
    final info = await PackageInfo.fromPlatform();

    final current = _fullVersion(info.version, info.buildNumber);

    final res = await http.get(Uri.parse(updateJsonUrl), headers: {
      'Accept': 'application/json',
      'User-Agent': 'Orbit-App',
      'Cache-Control': 'no-cache',
    });

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HTTP ${res.statusCode}');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;

    final latestVersion = (data['latest'] ?? '').toString().trim(); // z.B. 0.1.0-beta
    final latestBuild = (data['build'] ?? '').toString().trim();    // z.B. 2
    final notesRaw = (data['notes'] ?? '').toString().trim();
    final urlRaw = (data['url'] ?? '').toString().trim();

    if (latestVersion.isEmpty) {
      throw Exception('Update JSON: "latest" fehlt');
    }

    final latest = latestBuild.isNotEmpty ? '$latestVersion+$latestBuild' : latestVersion;

    final updateAvailable = _isNewerVersion(
      currentVersion: info.version,
      currentBuild: info.buildNumber,
      latestVersion: latestVersion,
      latestBuild: latestBuild,
    );

    return UpdateResult(
      updateAvailable: updateAvailable,
      current: current,
      latest: latest,
      notes: notesRaw.isEmpty ? null : notesRaw,
      url: urlRaw.isEmpty ? null : urlRaw,
    );
  }

  static String _fullVersion(String version, String buildNumber) {
    final v = version.trim();
    final b = buildNumber.trim();
    // Wenn buildNumber = "0" oder leer, zeigen wir ohne + an
    if (b.isEmpty || b == '0') return v;
    return '$v+$b';
    }

  static bool _isNewerVersion({
    required String currentVersion,
    required String currentBuild,
    required String latestVersion,
    required String latestBuild,
  }) {
    final vCmp = _compareSemverLike(currentVersion, latestVersion);
    if (vCmp < 0) return true; // latestVersion ist höher
    if (vCmp > 0) return false;

    // Version gleich -> Build vergleichen
    final cB = int.tryParse(currentBuild) ?? 0;
    final lB = int.tryParse(latestBuild) ?? 0;
    return lB > cB;
  }

  /// Vergleicht z.B.:
  /// 0.1.0-beta < 0.1.1-beta < 0.1.1
  static int _compareSemverLike(String a, String b) {
    final pa = _parse(a);
    final pb = _parse(b);

    // 1) Zahlen vergleichen
    for (int i = 0; i < 3; i++) {
      if (pa.nums[i] != pb.nums[i]) {
        return pa.nums[i] < pb.nums[i] ? -1 : 1;
      }
    }

    // 2) stable > prerelease
    if (pa.isPre != pb.isPre) {
      if (pa.isPre && !pb.isPre) return -1;
      if (!pa.isPre && pb.isPre) return 1;
    }

    // 3) beide prerelease -> tag vergleichen (alpha < beta < rc)
    return pa.preTag.compareTo(pb.preTag);
  }

  static _V _parse(String v) {
    var s = v.trim();

    // build weg
    if (s.contains('+')) s = s.split('+').first;

    String pre = '';
    if (s.contains('-')) {
      final parts = s.split('-');
      s = parts.first;
      pre = parts.sublist(1).join('-').toLowerCase();
    }

    final nums = s.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    while (nums.length < 3) nums.add(0);
    if (nums.length > 3) nums.removeRange(3, nums.length);

    // prerelease ranking string
    String tag;
    if (pre.startsWith('alpha')) tag = '0-alpha';
    else if (pre.startsWith('beta')) tag = '1-beta';
    else if (pre.startsWith('rc')) tag = '2-rc';
    else if (pre.isNotEmpty) tag = '3-$pre';
    else tag = '9-stable';

    return _V(nums: nums, isPre: pre.isNotEmpty, preTag: tag);
  }
}

class _V {
  final List<int> nums;
  final bool isPre;
  final String preTag;
  _V({required this.nums, required this.isPre, required this.preTag});
}