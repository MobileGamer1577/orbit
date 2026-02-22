import 'package:url_launcher/url_launcher.dart';

class InAppUpdateService {
  Future<void> downloadAndInstallApk({required String apkUrl}) async {
    final uri = Uri.parse(apkUrl);

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $apkUrl');
    }
  }
}
