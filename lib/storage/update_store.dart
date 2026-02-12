import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../services/update_service.dart';

class UpdateStore extends ChangeNotifier {
  bool isChecking = false;

  bool updateAvailable = false;
  String current = '';
  String latest = '';
  String? notes;
  String? url;

  String? error;

  UpdateResult? _result;
  UpdateResult? get result => _result;

  bool get checking => isChecking;

  bool _popupShownThisRun = false;

  /// Wird beim App-Start oder per Button aufgerufen
  Future<void> check() async {
    if (isChecking) return;
    isChecking = true;
    error = null;
    notifyListeners();

    try {
      final r = await UpdateService.checkForUpdates();
      _result = r;

      updateAvailable = r.updateAvailable;
      current = r.current;
      latest = r.latest;
      notes = r.notes;
      url = r.url;
    } catch (e) {
      error = e.toString();
      _result = null;
    } finally {
      isChecking = false;
      notifyListeners();
    }
  }

  /// Damit das Popup nicht bei jedem Screen-Rebuild wiederkommt
  bool get shouldShowPopup => updateAvailable && !_popupShownThisRun;
  void markPopupShown() {
    _popupShownThisRun = true;
  }

  /// APK runterladen und Installer öffnen (ohne Progressbar)
  Future<void> downloadAndInstall() async {
    final u = (url ?? '').trim();
    if (u.isEmpty) {
      throw Exception('Keine Update-URL vorhanden.');
    }

    final res = await http.get(Uri.parse(u));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Download fehlgeschlagen (HTTP ${res.statusCode})');
    }

    final dir = await getApplicationDocumentsDirectory();

    final fileName = _fileNameFromUrl(u).isNotEmpty
        ? _fileNameFromUrl(u)
        : 'orbit-update.apk';

    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(res.bodyBytes, flush: true);

    final r = await OpenFilex.open(file.path);

    if (kDebugMode) {
      // ignore: avoid_print
      print('OpenFilex result: ${r.type} / ${r.message}');
    }
  }

  String _fileNameFromUrl(String u) {
    try {
      final uri = Uri.parse(u);
      final last = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';
      if (last.toLowerCase().endsWith('.apk')) return last;
      return '';
    } catch (_) {
      return '';
    }
  }
}