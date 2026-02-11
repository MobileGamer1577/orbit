import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

class InAppUpdateService {
  /// Lädt die APK in den App-Cache und öffnet den Installer.
  /// Rückgabe: true = Installer geöffnet, false = ging nicht
  static Future<bool> downloadAndInstallApk({
    required String apkUrl,
    required void Function(int receivedBytes, int totalBytes)? onProgress,
  }) async {
    final uri = Uri.parse(apkUrl);

    final req = http.Request('GET', uri);
    final res = await http.Client().send(req);

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('APK Download HTTP ${res.statusCode}');
    }

    final total = res.contentLength ?? -1;

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/orbit_update.apk');

    // Falls schon existiert -> überschreiben
    if (await file.exists()) {
      await file.delete();
    }

    final sink = file.openWrite();
    int received = 0;

    try {
      await for (final chunk in res.stream) {
        received += chunk.length;
        sink.add(chunk);
        if (onProgress != null) onProgress(received, total);
      }
    } finally {
      await sink.flush();
      await sink.close();
    }

    final result = await OpenFilex.open(file.path);
    // result.type kann man auswerten, aber meistens reicht "opened"
    return result.type.name.toLowerCase() == 'done';
  }
}