import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/update_service.dart';

class UpdateStore extends ChangeNotifier {
  bool isChecking = false;
  bool get checking => isChecking;

  bool updateAvailable = false;
  String current = '';
  String latest = '';
  String? notes;

  /// ✅ Immer Release-Seite (keine APK-URL mehr)
  String releaseUrl = UpdateService.githubLatestReleaseUrl;

  String? error;

  bool _popupShownThisRun = false;

  Future<void> check() async {
    if (isChecking) return;
    isChecking = true;
    error = null;
    notifyListeners();

    try {
      final result = await UpdateService.checkForUpdates();
      updateAvailable = result.updateAvailable;
      current = result.current;
      latest = result.latest;
      notes = result.notes;
      releaseUrl = result.releaseUrl;
    } catch (e) {
      error = e.toString();
    } finally {
      isChecking = false;
      notifyListeners();
    }
  }

  bool get shouldShowPopup => updateAvailable && !_popupShownThisRun;

  void markPopupShown() {
    _popupShownThisRun = true;
  }

  /// ✅ Früher: APK runterladen & Installer öffnen
  /// Jetzt: Nur GitHub Release-Seite öffnen (manueller Download)
  Future<void> downloadAndInstall() async {
    await openLatestReleasePage();
  }

  Future<bool> openLatestReleasePage() async {
    final uri = Uri.parse(releaseUrl);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) {
      throw Exception('Konnte GitHub Release-Seite nicht öffnen.');
    }
    return ok;
  }
}