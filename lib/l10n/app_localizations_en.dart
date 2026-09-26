// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Sonata';

  @override
  String get playerTab => 'Player';

  @override
  String get libraryTab => 'Library';

  @override
  String get settingsTab => 'Settings';

  @override
  String get tvControlHint => 'Control mode · OK to select · Back to exit';

  @override
  String get tvNavigationHint =>
      'Menu held · ↑ Library · ↓ Playlists · ←→ Albums';

  @override
  String get libraryTitle => 'Library';

  @override
  String get songsTab => 'Songs';

  @override
  String get albumsTab => 'Albums';

  @override
  String get artistsTab => 'Artists';

  @override
  String get playlistsTab => 'Playlists';

  @override
  String get localFilesTab => 'Local Files';

  @override
  String get noSongs => 'No songs';

  @override
  String get noSongsHint => 'Your songs will appear here';

  @override
  String get noAlbums => 'No albums';

  @override
  String get noAlbumsHint => 'Your albums will appear here';

  @override
  String get noArtists => 'No artists';

  @override
  String get noArtistsHint => 'Your artists will appear here';

  @override
  String get noPlaylists => 'No playlists';

  @override
  String get noPlaylistsHint => 'Your playlists will appear here';

  @override
  String get createPlaylist => 'Create Playlist';

  @override
  String get noLocalFiles => 'No local files';

  @override
  String get scanning => 'Scanning...';

  @override
  String get scanLocalHint => 'Scan music folders or pick files';

  @override
  String get scanDefaultFolders => 'Scan Local Folders';

  @override
  String get pickFolder => 'Pick Folder';

  @override
  String localTracksCount(int count) {
    return '$count local tracks';
  }

  @override
  String get scanFolder => 'Scan folder';

  @override
  String get addAudioFiles => 'Add audio files';

  @override
  String get rescan => 'Rescan';

  @override
  String get loadingLibrary => 'Loading library...';

  @override
  String failedToLoadLibrary(String error) {
    return 'Failed to load library: $error';
  }

  @override
  String failedToScanLocalFiles(String error) {
    return 'Failed to scan local files: $error';
  }

  @override
  String get selectFolderToScan => 'Select folder to scan';

  @override
  String failedToScanFolder(String error) {
    return 'Failed to scan folder: $error';
  }

  @override
  String failedToPickFiles(String error) {
    return 'Failed to pick files: $error';
  }

  @override
  String addedToQueue(String title) {
    return 'Added \"$title\" to queue';
  }

  @override
  String get searchHint => 'Search for songs, albums, artists...';

  @override
  String get notConnected => 'Not connected to server';

  @override
  String searchFailed(String error) {
    return 'Search failed: $error';
  }

  @override
  String noResultsFor(String query) {
    return 'No results for \"$query\"';
  }

  @override
  String albumsCount(int albumCount) {
    return '$albumCount albums';
  }

  @override
  String songsCount(int songCount) {
    return '$songCount songs';
  }

  @override
  String artistStats(int albumCount, int songCount) {
    return '$albumCount albums • $songCount songs';
  }

  @override
  String get play => 'Play';

  @override
  String get addToQueue => 'Add to Queue';

  @override
  String get noTracksFound => 'No tracks found';

  @override
  String addedTracksToQueue(int count) {
    return 'Added $count tracks to queue';
  }

  @override
  String get noAlbumsFound => 'No albums found';

  @override
  String playlistStats(int songCount, String duration) {
    return '$songCount songs • $duration';
  }

  @override
  String get unknownArtist => 'Unknown Artist';

  @override
  String get unknownAlbum => 'Unknown Album';

  @override
  String get localFiles => 'Local Files';

  @override
  String get noTrackPlaying => 'No track playing';

  @override
  String get selectTrackToPlay => 'Select a track to play';

  @override
  String get noTrack => 'No Track';

  @override
  String get noLyricsAvailable => 'No lyrics available';

  @override
  String get playbackError => 'Playback error';

  @override
  String get queueEmpty => 'Queue is empty';

  @override
  String get addTracksToStart => 'Add tracks to start playing';

  @override
  String upNextCount(int count) {
    return 'Up Next ($count)';
  }

  @override
  String get clearQueue => 'Clear queue';

  @override
  String get closeQueue => 'Close queue';

  @override
  String get removeFromQueue => 'Remove from queue';

  @override
  String tracksRemaining(int count) {
    return '$count remaining tracks';
  }

  @override
  String get removeFromFavorites => 'Remove from favorites';

  @override
  String get addToFavorites => 'Add to favorites';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get navidromeSection => 'Navidrome / OpenSubsonic';

  @override
  String get serverUrl => 'Server URL';

  @override
  String get serverUrlHint => 'https://your-navidrome.example.com';

  @override
  String get username => 'Username';

  @override
  String get usernameHint => 'Enter your username';

  @override
  String get password => 'Password';

  @override
  String get passwordHint => 'Enter your password';

  @override
  String get apiKey => 'API Key (optional)';

  @override
  String get apiKeyHint => 'Or enter API key from Navidrome settings';

  @override
  String get enterApiKeyOrCredentials => 'Enter API key or username + password';

  @override
  String get connectionFailed => 'Connection failed - check credentials';

  @override
  String connectionError(String error) {
    return 'Error: $error';
  }

  @override
  String connectedTo(String url) {
    return 'Connected to $url';
  }

  @override
  String get testing => 'Testing...';

  @override
  String get testConnection => 'Test Connection';

  @override
  String get disconnect => 'Disconnect';

  @override
  String get appearance => 'Appearance';

  @override
  String get about => 'About';

  @override
  String get version => 'Version';

  @override
  String get licenses => 'Licenses';

  @override
  String get openSourceLicenses => 'Open source licenses';

  @override
  String get systemTheme => 'System';

  @override
  String get systemThemeHint => 'Follow device setting';

  @override
  String get lightTheme => 'Light';

  @override
  String get lightThemeHint => 'Always light';

  @override
  String get darkTheme => 'Dark';

  @override
  String get darkThemeHint => 'Always dark';

  @override
  String get localMusicSection => 'Local Music';

  @override
  String get localMusicDirsHint =>
      'Folders scanned for local audio files. Changes apply the next time you rescan from the Library tab.';

  @override
  String get addFolder => 'Add Folder';

  @override
  String get removeFolder => 'Remove Folder';

  @override
  String get restoreDefaultFolders => 'Restore Default Folders';

  @override
  String get noLocalDirs => 'No folders added yet';

  @override
  String get folderMissing => 'Folder not found';
}
