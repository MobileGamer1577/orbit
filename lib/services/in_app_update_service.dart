import 'package:url_launcher/url_launcher.dart';

class InAppUpdateService {
  /// Früher: APK laden & Installer öffnen.
  /// Jetzt: Nur GitHub Release-Seite öffnen (manueller Download).
  static Future<bool> downloadAndInstallApk({
    required String apkUrl,
    void Function(int received, int total)? onProgress,
  }) async {
    final uri = Uri.parse(apkUrl);

    // Kein Download mehr in der App → progress nur als "dummy"
    onProgress?.call(0, 0);

    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}