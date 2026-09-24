import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Flutter Music Player'**
  String get appTitle;

  /// No description provided for @playerTab.
  ///
  /// In en, this message translates to:
  /// **'Player'**
  String get playerTab;

  /// No description provided for @libraryTab.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get libraryTab;

  /// No description provided for @settingsTab.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTab;

  /// No description provided for @libraryTitle.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get libraryTitle;

  /// No description provided for @songsTab.
  ///
  /// In en, this message translates to:
  /// **'Songs'**
  String get songsTab;

  /// No description provided for @albumsTab.
  ///
  /// In en, this message translates to:
  /// **'Albums'**
  String get albumsTab;

  /// No description provided for @artistsTab.
  ///
  /// In en, this message translates to:
  /// **'Artists'**
  String get artistsTab;

  /// No description provided for @playlistsTab.
  ///
  /// In en, this message translates to:
  /// **'Playlists'**
  String get playlistsTab;

  /// No description provided for @localFilesTab.
  ///
  /// In en, this message translates to:
  /// **'Local Files'**
  String get localFilesTab;

  /// No description provided for @noSongs.
  ///
  /// In en, this message translates to:
  /// **'No songs'**
  String get noSongs;

  /// No description provided for @noSongsHint.
  ///
  /// In en, this message translates to:
  /// **'Your songs will appear here'**
  String get noSongsHint;

  /// No description provided for @noAlbums.
  ///
  /// In en, this message translates to:
  /// **'No albums'**
  String get noAlbums;

  /// No description provided for @noAlbumsHint.
  ///
  /// In en, this message translates to:
  /// **'Your albums will appear here'**
  String get noAlbumsHint;

  /// No description provided for @noArtists.
  ///
  /// In en, this message translates to:
  /// **'No artists'**
  String get noArtists;

  /// No description provided for @noArtistsHint.
  ///
  /// In en, this message translates to:
  /// **'Your artists will appear here'**
  String get noArtistsHint;

  /// No description provided for @noPlaylists.
  ///
  /// In en, this message translates to:
  /// **'No playlists'**
  String get noPlaylists;

  /// No description provided for @noPlaylistsHint.
  ///
  /// In en, this message translates to:
  /// **'Your playlists will appear here'**
  String get noPlaylistsHint;

  /// No description provided for @createPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Create Playlist'**
  String get createPlaylist;

  /// No description provided for @noLocalFiles.
  ///
  /// In en, this message translates to:
  /// **'No local files'**
  String get noLocalFiles;

  /// No description provided for @scanning.
  ///
  /// In en, this message translates to:
  /// **'Scanning...'**
  String get scanning;

  /// No description provided for @scanLocalHint.
  ///
  /// In en, this message translates to:
  /// **'Scan music folders or pick files'**
  String get scanLocalHint;

  /// No description provided for @scanDefaultFolders.
  ///
  /// In en, this message translates to:
  /// **'Scan Local Folders'**
  String get scanDefaultFolders;

  /// No description provided for @pickFolder.
  ///
  /// In en, this message translates to:
  /// **'Pick Folder'**
  String get pickFolder;

  /// No description provided for @localTracksCount.
  ///
  /// In en, this message translates to:
  /// **'{count} local tracks'**
  String localTracksCount(int count);

  /// No description provided for @scanFolder.
  ///
  /// In en, this message translates to:
  /// **'Scan folder'**
  String get scanFolder;

  /// No description provided for @addAudioFiles.
  ///
  /// In en, this message translates to:
  /// **'Add audio files'**
  String get addAudioFiles;

  /// No description provided for @rescan.
  ///
  /// In en, this message translates to:
  /// **'Rescan'**
  String get rescan;

  /// No description provided for @loadingLibrary.
  ///
  /// In en, this message translates to:
  /// **'Loading library...'**
  String get loadingLibrary;

  /// No description provided for @failedToLoadLibrary.
  ///
  /// In en, this message translates to:
  /// **'Failed to load library: {error}'**
  String failedToLoadLibrary(String error);

  /// No description provided for @failedToScanLocalFiles.
  ///
  /// In en, this message translates to:
  /// **'Failed to scan local files: {error}'**
  String failedToScanLocalFiles(String error);

  /// No description provided for @selectFolderToScan.
  ///
  /// In en, this message translates to:
  /// **'Select folder to scan'**
  String get selectFolderToScan;

  /// No description provided for @failedToScanFolder.
  ///
  /// In en, this message translates to:
  /// **'Failed to scan folder: {error}'**
  String failedToScanFolder(String error);

  /// No description provided for @failedToPickFiles.
  ///
  /// In en, this message translates to:
  /// **'Failed to pick files: {error}'**
  String failedToPickFiles(String error);

  /// No description provided for @addedToQueue.
  ///
  /// In en, this message translates to:
  /// **'Added \"{title}\" to queue'**
  String addedToQueue(String title);

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search for songs, albums, artists...'**
  String get searchHint;

  /// No description provided for @notConnected.
  ///
  /// In en, this message translates to:
  /// **'Not connected to server'**
  String get notConnected;

  /// No description provided for @searchFailed.
  ///
  /// In en, this message translates to:
  /// **'Search failed: {error}'**
  String searchFailed(String error);

  /// No description provided for @noResultsFor.
  ///
  /// In en, this message translates to:
  /// **'No results for \"{query}\"'**
  String noResultsFor(String query);

  /// No description provided for @albumsCount.
  ///
  /// In en, this message translates to:
  /// **'{albumCount} albums'**
  String albumsCount(int albumCount);

  /// No description provided for @songsCount.
  ///
  /// In en, this message translates to:
  /// **'{songCount} songs'**
  String songsCount(int songCount);

  /// No description provided for @artistStats.
  ///
  /// In en, this message translates to:
  /// **'{albumCount} albums • {songCount} songs'**
  String artistStats(int albumCount, int songCount);

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @addToQueue.
  ///
  /// In en, this message translates to:
  /// **'Add to Queue'**
  String get addToQueue;

  /// No description provided for @noTracksFound.
  ///
  /// In en, this message translates to:
  /// **'No tracks found'**
  String get noTracksFound;

  /// No description provided for @addedTracksToQueue.
  ///
  /// In en, this message translates to:
  /// **'Added {count} tracks to queue'**
  String addedTracksToQueue(int count);

  /// No description provided for @noAlbumsFound.
  ///
  /// In en, this message translates to:
  /// **'No albums found'**
  String get noAlbumsFound;

  /// No description provided for @playlistStats.
  ///
  /// In en, this message translates to:
  /// **'{songCount} songs • {duration}'**
  String playlistStats(int songCount, String duration);

  /// No description provided for @unknownArtist.
  ///
  /// In en, this message translates to:
  /// **'Unknown Artist'**
  String get unknownArtist;

  /// No description provided for @unknownAlbum.
  ///
  /// In en, this message translates to:
  /// **'Unknown Album'**
  String get unknownAlbum;

  /// No description provided for @localFiles.
  ///
  /// In en, this message translates to:
  /// **'Local Files'**
  String get localFiles;

  /// No description provided for @noTrackPlaying.
  ///
  /// In en, this message translates to:
  /// **'No track playing'**
  String get noTrackPlaying;

  /// No description provided for @selectTrackToPlay.
  ///
  /// In en, this message translates to:
  /// **'Select a track to play'**
  String get selectTrackToPlay;

  /// No description provided for @noTrack.
  ///
  /// In en, this message translates to:
  /// **'No Track'**
  String get noTrack;

  /// No description provided for @noLyricsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No lyrics available'**
  String get noLyricsAvailable;

  /// No description provided for @playbackError.
  ///
  /// In en, this message translates to:
  /// **'Playback error'**
  String get playbackError;

  /// No description provided for @queueEmpty.
  ///
  /// In en, this message translates to:
  /// **'Queue is empty'**
  String get queueEmpty;

  /// No description provided for @addTracksToStart.
  ///
  /// In en, this message translates to:
  /// **'Add tracks to start playing'**
  String get addTracksToStart;

  /// No description provided for @upNextCount.
  ///
  /// In en, this message translates to:
  /// **'Up Next ({count})'**
  String upNextCount(int count);

  /// No description provided for @clearQueue.
  ///
  /// In en, this message translates to:
  /// **'Clear queue'**
  String get clearQueue;

  /// No description provided for @closeQueue.
  ///
  /// In en, this message translates to:
  /// **'Close queue'**
  String get closeQueue;

  /// No description provided for @removeFromQueue.
  ///
  /// In en, this message translates to:
  /// **'Remove from queue'**
  String get removeFromQueue;

  /// No description provided for @tracksRemaining.
  ///
  /// In en, this message translates to:
  /// **'{count} remaining tracks'**
  String tracksRemaining(int count);

  /// No description provided for @removeFromFavorites.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get removeFromFavorites;

  /// No description provided for @addToFavorites.
  ///
  /// In en, this message translates to:
  /// **'Add to favorites'**
  String get addToFavorites;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @navidromeSection.
  ///
  /// In en, this message translates to:
  /// **'Navidrome / OpenSubsonic'**
  String get navidromeSection;

  /// No description provided for @serverUrl.
  ///
  /// In en, this message translates to:
  /// **'Server URL'**
  String get serverUrl;

  /// No description provided for @serverUrlHint.
  ///
  /// In en, this message translates to:
  /// **'https://your-navidrome.example.com'**
  String get serverUrlHint;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @usernameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your username'**
  String get usernameHint;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get passwordHint;

  /// No description provided for @apiKey.
  ///
  /// In en, this message translates to:
  /// **'API Key (optional)'**
  String get apiKey;

  /// No description provided for @apiKeyHint.
  ///
  /// In en, this message translates to:
  /// **'Or enter API key from Navidrome settings'**
  String get apiKeyHint;

  /// No description provided for @enterApiKeyOrCredentials.
  ///
  /// In en, this message translates to:
  /// **'Enter API key or username + password'**
  String get enterApiKeyOrCredentials;

  /// No description provided for @connectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Connection failed - check credentials'**
  String get connectionFailed;

  /// No description provided for @connectionError.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String connectionError(String error);

  /// No description provided for @connectedTo.
  ///
  /// In en, this message translates to:
  /// **'Connected to {url}'**
  String connectedTo(String url);

  /// No description provided for @testing.
  ///
  /// In en, this message translates to:
  /// **'Testing...'**
  String get testing;

  /// No description provided for @testConnection.
  ///
  /// In en, this message translates to:
  /// **'Test Connection'**
  String get testConnection;

  /// No description provided for @disconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get disconnect;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @licenses.
  ///
  /// In en, this message translates to:
  /// **'Licenses'**
  String get licenses;

  /// No description provided for @openSourceLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open source licenses'**
  String get openSourceLicenses;

  /// No description provided for @systemTheme.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get systemTheme;

  /// No description provided for @systemThemeHint.
  ///
  /// In en, this message translates to:
  /// **'Follow device setting'**
  String get systemThemeHint;

  /// No description provided for @lightTheme.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get lightTheme;

  /// No description provided for @lightThemeHint.
  ///
  /// In en, this message translates to:
  /// **'Always light'**
  String get lightThemeHint;

  /// No description provided for @darkTheme.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get darkTheme;

  /// No description provided for @darkThemeHint.
  ///
  /// In en, this message translates to:
  /// **'Always dark'**
  String get darkThemeHint;

  /// No description provided for @localMusicSection.
  ///
  /// In en, this message translates to:
  /// **'Local Music'**
  String get localMusicSection;

  /// No description provided for @localMusicDirsHint.
  ///
  /// In en, this message translates to:
  /// **'Folders scanned for local audio files. Changes apply the next time you rescan from the Library tab.'**
  String get localMusicDirsHint;

  /// No description provided for @addFolder.
  ///
  /// In en, this message translates to:
  /// **'Add Folder'**
  String get addFolder;

  /// No description provided for @removeFolder.
  ///
  /// In en, this message translates to:
  /// **'Remove Folder'**
  String get removeFolder;

  /// No description provided for @restoreDefaultFolders.
  ///
  /// In en, this message translates to:
  /// **'Restore Default Folders'**
  String get restoreDefaultFolders;

  /// No description provided for @noLocalDirs.
  ///
  /// In en, this message translates to:
  /// **'No folders added yet'**
  String get noLocalDirs;

  /// No description provided for @folderMissing.
  ///
  /// In en, this message translates to:
  /// **'Folder not found'**
  String get folderMissing;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
