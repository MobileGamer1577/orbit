import 'package:flutter/material.dart';

// ──────────────────────────────────────────────────────────────
// Extension – einfacher Zugriff: context.l10n.xxx
// ──────────────────────────────────────────────────────────────
extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

// ──────────────────────────────────────────────────────────────
// Abstrakte Basis
// ──────────────────────────────────────────────────────────────
abstract class AppLocalizations {
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  // ── Settings ──────────────────────────────────────────────
  String get settingsTitle;
  String get sectionGeneral;
  String get version;
  String get languageLabel;
  String get sectionUpdates;
  String get updateStatus;
  String get updateChecking;
  String get updateCurrent;
  String get updateCheckBtn;
  String get updateNoUpdate;
  String get updateFailed;
  String get updateGithubFailed;
  String get sectionReset;
  String get resetProgress;
  String get resetProgressSubtitle;
  String get resetProgressDone;
  String get updateDialogLater;
  String get updateDialogOpen;
  String get updateDialogNotes;

  // ── Game Select ───────────────────────────────────────────
  String get gameSelectSubtitle;
  String get fortniteSubtitle;
  String get bo7Subtitle;
  String get updateChecking2; // kurze Version für Button
  String get updateCheckButton;

  // ── Fortnite Hub ──────────────────────────────────────────
  String get hubWhatOpen;
  String get hubCountdowns;
  String get hubCountdownsSubtitle;
  String get hubQuests;
  String get hubQuestsSubtitle;
  String get hubItemShop;
  String get hubItemShopSubtitle;
  String get hubStats;
  String get hubStatsSubtitle;
  String get hubStatsSoon;
  String get hubLocker;
  String get hubLockerSubtitle;
  String get hubFestival;
  String get hubFestivalSubtitle;
  String get hubServerStatus;
  String get hubServerStatusSubtitle;
  String get hubServerStatusSoon;

  // ── Countdown ─────────────────────────────────────────────
  String get countdownTitle;
  String get countdownSubtitle;
  String get countdownExpired;
  String get countdownExpiringSoon;
  String get countdownActive;
  String get countdownDays;
  String countdownDayProgress(int elapsed, int total);
  List<String> get monthNames;

  // ── Festival Hub ──────────────────────────────────────────
  String get festivalWhatOpen;
  String get festivalSearchSongs;
  String get festivalSearchSongsSubtitle;
  String get festivalCreatePlaylist;
  String get festivalCreatePlaylistSubtitle;
  String get festivalWishlistNotifications;
  String get festivalWishlistNotificationsSubtitle;
  String get comingSoon;

  // ── Festival Playlist ─────────────────────────────────────
  String get festivalPlaylistTitle;
  String get festivalPlaylistBody;

  // ── Festival Search ───────────────────────────────────────
  String get festivalSearchTitle;
  String get festivalSearchHint;
  String festivalSongCount(int n);
  String get noResults;

  // ── Locker ────────────────────────────────────────────────
  String get lockerTitle;
  String get lockerSubtitle;
  String get lockerSearchHint;
  String get filterAll;
  String get filterOwned;
  String get filterWishlist;

  // ── Item Shop ─────────────────────────────────────────────
  String get shopTitle;
  String shopUpdatedAt(String time, int count);
  String get shopLoading;
  String get shopError;
  String get shopEmpty;
  String get shopRetry;

  // ── Mode Select ───────────────────────────────────────────
  String get modeSelectSubtitle;

  // Fortnite Modes
  String get modeBRTitle;
  String get modeBRSubtitle;
  String get modeReloadTitle;
  String get modeReloadSubtitle;
  String get modeBallisticTitle;
  String get modeBallisticSubtitle;
  String get modeLegoTitle;
  String get modeLegoSubtitle;
  String get modeDeluluTitle;
  String get modeDeluluSubtitle;
  String get modeBlitzTitle;
  String get modeBlitzSubtitle;
  String get modeOGTitle;
  String get modeOGSubtitle;

  // BO7 Modes
  String get modeBo7CoopTitle;
  String get modeBo7CoopSubtitle;
  String get modeBo7MPTitle;
  String get modeBo7MPSubtitle;
  String get modeBo7ZombiesTitle;
  String get modeBo7ZombiesSubtitle;
  String get modeBo7WarzoneTitle;
  String get modeBo7WarzoneSubtitle;

  // ── Task List ─────────────────────────────────────────────
  String get taskComingSoon;
  String get taskSearchHint;
  String taskQuestCount(int n);

  // ── Song Details ──────────────────────────────────────────
  String get songOwned;
  String get songOwn;
  String get songOnWishlist;
  String get songWishlist;
  String get songDifficulty;
  String get songNoData;
  String get songDetails;
  String get songSource;
  String get songBpm;
  String get songAdded;
  String get songDuration;
  String get songVocalPro;
  String get songVocalProYes;
  String get songVocalProNo;
  String get songId;
  String get songLoadingDifficulty;
  String get instrumentVocals;
  String get instrumentLead;
  String get instrumentBass;
  String get instrumentDrums;

  // ── Update Dialog ─────────────────────────────────────────
  String updateAvailableTitle(String version);
}

// ──────────────────────────────────────────────────────────────
// Delegate
// ──────────────────────────────────────────────────────────────
class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['de', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      locale.languageCode == 'en'
          ? _AppLocalizationsEn()
          : _AppLocalizationsDe();

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}

// ──────────────────────────────────────────────────────────────
// 🇩🇪 Deutsch
// ──────────────────────────────────────────────────────────────
class _AppLocalizationsDe extends AppLocalizations {
  // Settings
  @override String get settingsTitle        => 'Einstellungen';
  @override String get sectionGeneral       => 'Allgemein';
  @override String get version              => 'Version';
  @override String get languageLabel        => 'Sprache / Language';
  @override String get sectionUpdates       => 'Updates';
  @override String get updateStatus         => 'Update-Status';
  @override String get updateChecking       => 'Wird geprüft…';
  @override String get updateCurrent        => 'Aktuell ✅';
  @override String get updateCheckBtn       => 'Check';
  @override String get updateNoUpdate       => 'Keine Updates gefunden ✅';
  @override String get updateFailed         => 'Update-Check fehlgeschlagen.';
  @override String get updateGithubFailed   => 'GitHub konnte nicht geöffnet werden.';
  @override String get sectionReset         => 'Zurücksetzen';
  @override String get resetProgress        => 'Fortschritt zurücksetzen';
  @override String get resetProgressSubtitle => 'Checkbox-Status löschen';
  @override String get resetProgressDone    => 'Fortschritt zurückgesetzt ✅';
  @override String get updateDialogLater    => 'Später';
  @override String get updateDialogOpen     => 'Release öffnen';
  @override String get updateDialogNotes    => 'Release Notes fehlen.';

  // Game Select
  @override String get gameSelectSubtitle   => 'Wähle ein Spiel';
  @override String get fortniteSubtitle     => 'Aufgaben • Season-Countdown • Item-Shop';
  @override String get bo7Subtitle          => 'Steam Erfolge • PlayStation Trophäen • Modi';
  @override String get updateChecking2      => 'Prüfe…';
  @override String get updateCheckButton    => 'Updates prüfen';

  // Fortnite Hub
  @override String get hubWhatOpen              => 'Was willst du öffnen?';
  @override String get hubCountdowns            => 'Countdowns';
  @override String get hubCountdownsSubtitle    => 'Season Pässe & Ablaufdaten';
  @override String get hubQuests                => 'Aufträge';
  @override String get hubQuestsSubtitle        => 'BR, Reload, Ballistic, LEGO, OG…';
  @override String get hubItemShop              => 'Item-Shop';
  @override String get hubItemShopSubtitle      => 'Täglicher Shop • stündlich aktualisiert';
  @override String get hubStats                 => 'Stats';
  @override String get hubStatsSubtitle         => 'Kommt bald';
  @override String get hubStatsSoon             => 'Stats kommen bald ✅';
  @override String get hubLocker                => 'Spind';
  @override String get hubLockerSubtitle        => 'Alle Cosmetics (aktuell: Songs)';
  @override String get hubFestival              => 'Festival';
  @override String get hubFestivalSubtitle      => 'Songs suchen & Playlist bauen';
  @override String get hubServerStatus          => 'Status';
  @override String get hubServerStatusSubtitle  => 'Kommt bald (Server/Services)';
  @override String get hubServerStatusSoon      => 'Status kommt bald ✅';

  // Countdown
  @override String get countdownTitle       => 'Countdowns';
  @override String get countdownSubtitle    => 'Fortnite Season Pässe';
  @override String get countdownExpired     => 'Abgelaufen';
  @override String get countdownExpiringSoon => 'Läuft bald ab!';
  @override String get countdownActive      => 'Aktiv';
  @override String get countdownDays        => 'Tage';
  @override String countdownDayProgress(int elapsed, int total) => 'Tag $elapsed / $total';
  @override List<String> get monthNames => const [
    'Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun',
    'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez',
  ];

  // Festival Hub
  @override String get festivalWhatOpen                     => 'Was willst du öffnen?';
  @override String get festivalSearchSongs                  => 'Songs suchen';
  @override String get festivalSearchSongsSubtitle          => 'Nach Song / Artist / Song-ID suchen';
  @override String get festivalCreatePlaylist               => 'Playlist erstellen';
  @override String get festivalCreatePlaylistSubtitle       => 'Rotation • Besitz • Alle Songs (bald mehr)';
  @override String get festivalWishlistNotifications        => 'Wishlist-Benachrichtigungen';
  @override String get festivalWishlistNotificationsSubtitle => 'Kommt später, sobald wir eine Shop-API haben';
  @override String get comingSoon                           => 'Kommt bald ✅';

  // Festival Playlist
  @override String get festivalPlaylistTitle => 'Playlist';
  @override String get festivalPlaylistBody  =>
      'Kommt bald ✅\n\nGeplant:\n• Playlist aus Weekly Rotation\n• Playlist aus deinen Owned-Songs\n• Playlist aus ALLEN Songs\n\n(Tipp: Owned/Wishlist kannst du schon in der Song-Suche setzen.)';

  // Festival Search
  @override String get festivalSearchTitle  => 'Songs suchen';
  @override String get festivalSearchHint   => 'Song, Artist oder ID…';
  @override String festivalSongCount(int n) => '$n Songs';
  @override String get noResults            => 'Keine Treffer.';

  // Locker
  @override String get lockerTitle      => 'Spind';
  @override String get lockerSubtitle   => 'Festival-Songs • Schwierigkeit via API';
  @override String get lockerSearchHint => 'Song / Artist / ID suchen…';
  @override String get filterAll        => 'Alle';
  @override String get filterOwned      => 'Im Besitz';
  @override String get filterWishlist   => 'Wunschliste';

  // Item Shop
  @override String get shopTitle   => 'Item Shop';
  @override String shopUpdatedAt(String time, int count) =>
      'Aktualisiert: $time • $count Einträge';
  @override String get shopLoading => 'Shop wird geladen…';
  @override String get shopError   => 'Shop konnte nicht geladen werden';
  @override String get shopEmpty   => 'Keine Einträge gefunden.';
  @override String get shopRetry   => 'Erneut versuchen';

  // Mode Select
  @override String get modeSelectSubtitle => 'Wähle einen Modus';
  @override String get modeBRTitle        => 'Battle Royale';
  @override String get modeBRSubtitle     => 'Aufträge für Battle Royale';
  @override String get modeReloadTitle    => 'Fortnite Reload';
  @override String get modeReloadSubtitle => 'Aufträge für Reload';
  @override String get modeBallisticTitle    => 'Ballistic';
  @override String get modeBallisticSubtitle => 'Aufträge für Ballistic';
  @override String get modeLegoTitle    => 'LEGO Fortnite';
  @override String get modeLegoSubtitle => 'Aufträge für LEGO Fortnite';
  @override String get modeDeluluTitle    => 'Delulu';
  @override String get modeDeluluSubtitle => 'Aufträge für Delulu';
  @override String get modeBlitzTitle    => 'Blitz Royale';
  @override String get modeBlitzSubtitle => 'Aufträge für Blitz Royale';
  @override String get modeOGTitle    => 'OG';
  @override String get modeOGSubtitle => 'Aufträge für OG Fortnite';
  @override String get modeBo7CoopTitle      => 'Koop & Endspiel';
  @override String get modeBo7CoopSubtitle   => 'Weekly-Aufgaben (Soon) • Visitenkarten (Soon)';
  @override String get modeBo7MPTitle        => 'Mehrspieler';
  @override String get modeBo7MPSubtitle     => 'Erfolge • Weekly-Aufgaben (Soon) • Tarnungen (Soon)';
  @override String get modeBo7ZombiesTitle   => 'Zombies';
  @override String get modeBo7ZombiesSubtitle => 'Erfolge • Weekly-Aufgaben (Soon) • Tarnungen (Soon)';
  @override String get modeBo7WarzoneTitle   => 'Warzone';
  @override String get modeBo7WarzoneSubtitle => 'Weekly-Aufgaben (Soon) • Visitenkarten (Soon)';

  // Task List
  @override String get taskComingSoon  => 'Kommt bald ✅';
  @override String get taskSearchHint  => 'Suchen…';
  @override String taskQuestCount(int n) => '$n Aufträge';

  // Song Details
  @override String get songOwned          => 'Im Besitz';
  @override String get songOwn            => 'Besitzen';
  @override String get songOnWishlist     => 'Auf Wunschliste';
  @override String get songWishlist       => 'Wunschliste';
  @override String get songDifficulty     => 'Schwierigkeit';
  @override String get songNoData         => 'Keine Daten verfügbar';
  @override String get songDetails        => 'Details';
  @override String get songSource         => 'Quelle';
  @override String get songBpm            => 'BPM';
  @override String get songAdded          => 'Hinzugefügt';
  @override String get songDuration       => 'Länge';
  @override String get songVocalPro       => 'Vocal Pro';
  @override String get songVocalProYes    => 'Ja ✓';
  @override String get songVocalProNo     => 'Nein';
  @override String get songId             => 'Song-ID';
  @override String get songLoadingDifficulty => 'Lade Schwierigkeitsdaten…';
  @override String get instrumentVocals   => 'Gesang';
  @override String get instrumentLead     => 'Lead';
  @override String get instrumentBass     => 'Bass';
  @override String get instrumentDrums    => 'Drums';

  @override String updateAvailableTitle(String version) => 'Update verfügbar: $version';
}

// ──────────────────────────────────────────────────────────────
// 🇬🇧 English
// ──────────────────────────────────────────────────────────────
class _AppLocalizationsEn extends AppLocalizations {
  // Settings
  @override String get settingsTitle        => 'Settings';
  @override String get sectionGeneral       => 'General';
  @override String get version              => 'Version';
  @override String get languageLabel        => 'Language';
  @override String get sectionUpdates       => 'Updates';
  @override String get updateStatus         => 'Update Status';
  @override String get updateChecking       => 'Checking…';
  @override String get updateCurrent        => 'Up to date ✅';
  @override String get updateCheckBtn       => 'Check';
  @override String get updateNoUpdate       => 'No updates found ✅';
  @override String get updateFailed         => 'Update check failed.';
  @override String get updateGithubFailed   => 'Could not open GitHub.';
  @override String get sectionReset         => 'Reset';
  @override String get resetProgress        => 'Reset Progress';
  @override String get resetProgressSubtitle => 'Clear checkbox state';
  @override String get resetProgressDone    => 'Progress reset ✅';
  @override String get updateDialogLater    => 'Later';
  @override String get updateDialogOpen     => 'Open release';
  @override String get updateDialogNotes    => 'No release notes available.';

  // Game Select
  @override String get gameSelectSubtitle   => 'Choose a game';
  @override String get fortniteSubtitle     => 'Quests • Season Countdown • Item Shop';
  @override String get bo7Subtitle          => 'Steam Achievements • PlayStation Trophies • Modes';
  @override String get updateChecking2      => 'Checking…';
  @override String get updateCheckButton    => 'Check for updates';

  // Fortnite Hub
  @override String get hubWhatOpen              => 'What do you want to open?';
  @override String get hubCountdowns            => 'Countdowns';
  @override String get hubCountdownsSubtitle    => 'Season Passes & expiry dates';
  @override String get hubQuests                => 'Quests';
  @override String get hubQuestsSubtitle        => 'BR, Reload, Ballistic, LEGO, OG…';
  @override String get hubItemShop              => 'Item Shop';
  @override String get hubItemShopSubtitle      => 'Daily shop • updated hourly';
  @override String get hubStats                 => 'Stats';
  @override String get hubStatsSubtitle         => 'Coming soon';
  @override String get hubStatsSoon             => 'Stats coming soon ✅';
  @override String get hubLocker                => 'Locker';
  @override String get hubLockerSubtitle        => 'All cosmetics (currently: songs)';
  @override String get hubFestival              => 'Festival';
  @override String get hubFestivalSubtitle      => 'Search songs & build playlists';
  @override String get hubServerStatus          => 'Status';
  @override String get hubServerStatusSubtitle  => 'Coming soon (server/services)';
  @override String get hubServerStatusSoon      => 'Status coming soon ✅';

  // Countdown
  @override String get countdownTitle        => 'Countdowns';
  @override String get countdownSubtitle     => 'Fortnite Season Passes';
  @override String get countdownExpired      => 'Expired';
  @override String get countdownExpiringSoon => 'Expiring soon!';
  @override String get countdownActive       => 'Active';
  @override String get countdownDays         => 'Days';
  @override String countdownDayProgress(int elapsed, int total) => 'Day $elapsed / $total';
  @override List<String> get monthNames => const [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  // Festival Hub
  @override String get festivalWhatOpen                      => 'What do you want to open?';
  @override String get festivalSearchSongs                   => 'Search songs';
  @override String get festivalSearchSongsSubtitle           => 'Search by song / artist / song ID';
  @override String get festivalCreatePlaylist                => 'Create playlist';
  @override String get festivalCreatePlaylistSubtitle        => 'Rotation • Owned • All songs (more coming)';
  @override String get festivalWishlistNotifications         => 'Wishlist notifications';
  @override String get festivalWishlistNotificationsSubtitle => 'Coming later once we have a shop API';
  @override String get comingSoon                            => 'Coming soon ✅';

  // Festival Playlist
  @override String get festivalPlaylistTitle => 'Playlist';
  @override String get festivalPlaylistBody  =>
      'Coming soon ✅\n\nPlanned:\n• Playlist from weekly rotation\n• Playlist from your owned songs\n• Playlist from ALL songs\n\n(Tip: You can already set Owned/Wishlist in the song search.)';

  // Festival Search
  @override String get festivalSearchTitle  => 'Search songs';
  @override String get festivalSearchHint   => 'Song, artist or ID…';
  @override String festivalSongCount(int n) => '$n songs';
  @override String get noResults            => 'No results.';

  // Locker
  @override String get lockerTitle      => 'Locker';
  @override String get lockerSubtitle   => 'Festival songs • Difficulty via API';
  @override String get lockerSearchHint => 'Search song / artist / ID…';
  @override String get filterAll        => 'All';
  @override String get filterOwned      => 'Owned';
  @override String get filterWishlist   => 'Wishlist';

  // Item Shop
  @override String get shopTitle   => 'Item Shop';
  @override String shopUpdatedAt(String time, int count) =>
      'Updated: $time • $count entries';
  @override String get shopLoading => 'Loading shop…';
  @override String get shopError   => 'Could not load shop';
  @override String get shopEmpty   => 'No entries found.';
  @override String get shopRetry   => 'Retry';

  // Mode Select
  @override String get modeSelectSubtitle => 'Choose a mode';
  @override String get modeBRTitle        => 'Battle Royale';
  @override String get modeBRSubtitle     => 'Battle Royale quests';
  @override String get modeReloadTitle    => 'Fortnite Reload';
  @override String get modeReloadSubtitle => 'Reload quests';
  @override String get modeBallisticTitle    => 'Ballistic';
  @override String get modeBallisticSubtitle => 'Ballistic quests';
  @override String get modeLegoTitle    => 'LEGO Fortnite';
  @override String get modeLegoSubtitle => 'LEGO Fortnite quests';
  @override String get modeDeluluTitle    => 'Delulu';
  @override String get modeDeluluSubtitle => 'Delulu quests';
  @override String get modeBlitzTitle    => 'Blitz Royale';
  @override String get modeBlitzSubtitle => 'Blitz Royale quests';
  @override String get modeOGTitle    => 'OG';
  @override String get modeOGSubtitle => 'OG Fortnite quests';
  @override String get modeBo7CoopTitle      => 'Co-op & Endgame';
  @override String get modeBo7CoopSubtitle   => 'Weekly challenges (Soon) • Calling cards (Soon)';
  @override String get modeBo7MPTitle        => 'Multiplayer';
  @override String get modeBo7MPSubtitle     => 'Achievements • Weekly (Soon) • Camos (Soon)';
  @override String get modeBo7ZombiesTitle   => 'Zombies';
  @override String get modeBo7ZombiesSubtitle => 'Achievements • Weekly (Soon) • Camos (Soon)';
  @override String get modeBo7WarzoneTitle   => 'Warzone';
  @override String get modeBo7WarzoneSubtitle => 'Weekly challenges (Soon) • Calling cards (Soon)';

  // Task List
  @override String get taskComingSoon  => 'Coming soon ✅';
  @override String get taskSearchHint  => 'Search…';
  @override String taskQuestCount(int n) => '$n quests';

  // Song Details
  @override String get songOwned          => 'Owned';
  @override String get songOwn            => 'Own';
  @override String get songOnWishlist     => 'On wishlist';
  @override String get songWishlist       => 'Wishlist';
  @override String get songDifficulty     => 'Difficulty';
  @override String get songNoData         => 'No data available';
  @override String get songDetails        => 'Details';
  @override String get songSource         => 'Source';
  @override String get songBpm            => 'BPM';
  @override String get songAdded          => 'Added';
  @override String get songDuration       => 'Duration';
  @override String get songVocalPro       => 'Vocal Pro';
  @override String get songVocalProYes    => 'Yes ✓';
  @override String get songVocalProNo     => 'No';
  @override String get songId             => 'Song ID';
  @override String get songLoadingDifficulty => 'Loading difficulty data…';
  @override String get instrumentVocals   => 'Vocals';
  @override String get instrumentLead     => 'Lead';
  @override String get instrumentBass     => 'Bass';
  @override String get instrumentDrums    => 'Drums';

  @override String updateAvailableTitle(String version) => 'Update available: $version';
}
