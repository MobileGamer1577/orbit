import 'package:url_launcher/url_launcher.dart';

class InAppUpdateService {
  /// Öffnet nur die GitHub Release-Seite (manueller Download).
  static Future<void> downloadAndInstallApk({
    required String apkUrl,
    void Function(int received, int total)? onProgress,
  }) async {
    final uri = Uri.parse(apkUrl);

    // Dummy progress (falls du später Progress anzeigen willst)
    onProgress?.call(0, 0);

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) {
      throw Exception('Could not launch $apkUrl');
    }
  }
}
