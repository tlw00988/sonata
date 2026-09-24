import 'dart:io';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';

class LocalFileRepository {
  static const List<String> _audioExtensions = [
    '.mp3',
    '.flac',
    '.wav',
    '.ogg',
    '.m4a',
    '.aac',
    '.opus',
    '.wma',
    '.ape',
    '.aif',
    '.aiff',
  ];

  /// Cover images commonly placed next to an album's tracks, in preference
  /// order. Matched case-insensitively within the track's own folder.
  static const List<String> _sidecarCovers = [
    'cover',
    'folder',
    'front',
    'album',
    'albumart',
    'album_art',
    'art',
  ];

  static const List<String> _sidecarCoverExtensions = [
    '.jpg',
    '.jpeg',
    '.png',
    '.webp',
  ];

  /// Directory listings keyed by parent path, so scanning one album folder
  /// does not re-list it for every track it contains.
  final Map<String, Map<String, String>> _dirIndex = {};

  /// Preference key holding the folders walked by [scanForAudioFiles].
  static const String localDirsPrefKey = 'local_music_dirs';

  Future<List<Track>> scanForAudioFiles() async {
    final tracks = <Track>[];

    for (final path in await getScanDirectories()) {
      final dir = Directory(path);
      if (await dir.exists()) {
        await _scanDirectory(dir, tracks);
      }
    }

    return tracks;
  }

  /// The folders to scan, in the order they appear in the library.
  ///
  /// The first call stores this platform's defaults so the settings screen
  /// has something to list and edit; from then on the stored list is the
  /// only source of truth, including when the user has emptied it.
  Future<List<String>> getScanDirectories() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(localDirsPrefKey);
    if (saved != null) return normalizeDirList(saved);

    final defaults = normalizeDirList(await defaultDirectories());
    await prefs.setStringList(localDirsPrefKey, defaults);
    return defaults;
  }

  /// Persists [dirs] as the scan list and returns it cleaned up, so callers
  /// can rebuild their state from what was actually stored.
  Future<List<String>> saveScanDirectories(List<String> dirs) async {
    final normalized = normalizeDirList(dirs);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(localDirsPrefKey, normalized);
    return normalized;
  }

  /// The folders this platform ships with, before the user edits them.
  ///
  /// Each lookup is isolated: a platform that does not provide a given
  /// location simply skips it instead of failing the whole scan.
  Future<List<String>> defaultDirectories() async {
    final directories = <String>[];

    // Android/iOS app-specific storage
    try {
      final extDir = await getExternalStorageDirectory();
      if (extDir != null) {
        directories.add('${extDir.path}/Music');
        directories.add('${extDir.path}/Download');
      }
    } catch (e) {
      // Not on Android, or the platform channel is unavailable.
    }

    // Windows
    try {
      final userProfile = Platform.environment['USERPROFILE'];
      if (userProfile != null) {
        directories.add('$userProfile\\Music');
        directories.add('$userProfile\\Downloads');
        directories.add('$userProfile\\Desktop');
      }
    } catch (e) {
      // Ignore
    }

    // Linux/macOS
    try {
      final homeDir = Platform.environment['HOME'] ?? '';
      if (homeDir.isNotEmpty) {
        directories.add('$homeDir/Music');
        directories.add('$homeDir/Downloads');
      }
    } catch (e) {
      // Ignore
    }

    return directories;
  }

  /// Trims entries, drops blanks, strips trailing separators and removes
  /// duplicates while keeping their first position, so a hand-edited list
  /// never scans the same folder twice.
  static List<String> normalizeDirList(List<String> dirs) {
    final seen = <String>{};
    final normalized = <String>[];

    for (final dir in dirs) {
      var path = dir.trim();
      while (path.length > 1 &&
          (path.endsWith('/') || path.endsWith(r'\')) &&
          !_isDriveRoot(path)) {
        path = path.substring(0, path.length - 1);
      }
      if (path.isEmpty) continue;
      if (seen.add(path)) normalized.add(path);
    }

    return normalized;
  }

  /// `C:\` and friends: stripping the separator would turn the root into a
  /// drive-relative path.
  static bool _isDriveRoot(String path) =>
      path.length == 3 && path[1] == ':' && path[0] != path[2];

  Future<void> _scanDirectory(Directory dir, List<Track> tracks) async {
    try {
      await for (final entity in dir.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is File) {
          final extension = '.${entity.path.split('.').last.toLowerCase()}';
          if (_audioExtensions.contains(extension)) {
            final track = await trackFromFile(entity.path);
            if (track != null) {
              tracks.add(track);
            }
          }
        }
      }
    } catch (e) {
      // Ignore permission errors
    } finally {
      _dirIndex.clear();
    }
  }

  Future<List<Track>> scanDirectory(String dirPath) async {
    final tracks = <Track>[];
    final dir = Directory(dirPath);
    if (await dir.exists()) {
      await _scanDirectory(dir, tracks);
    }
    return tracks;
  }

  /// Builds a [Track] for a single audio file, reading its tags.
  ///
  /// Falls back to parsing `Artist - Title` out of the file name when the
  /// tags are missing or the format carries no readable metadata.
  Future<Track?> trackFromFile(
    String path, {
    String unknownArtist = 'Unknown Artist',
    String unknownAlbum = 'Unknown Album',
  }) async {
    final file = File(path);
    if (!await file.exists()) return null;

    final fallback = _titleFromFileName(path);
    var title = fallback.title;
    var artist = unknownArtist;
    var album = unknownAlbum;
    var duration = 0;
    var trackNumber = 0;
    var year = 0;
    var genre = '';
    String? coverPath;

    AudioMetadata? metadata;
    try {
      metadata = readMetadata(file, getImage: true);
    } catch (e) {
      // Unreadable tags (or an unsupported container): keep the fallbacks.
    }

    if (metadata != null) {
      title = _firstNonEmpty(metadata.title) ?? fallback.title;
      artist =
          _firstNonEmpty(metadata.artist) ??
          _firstNonEmpty(metadata.albumArtist) ??
          (fallback.artist ?? unknownArtist);
      album = _firstNonEmpty(metadata.album) ?? unknownAlbum;
      duration = metadata.duration?.inSeconds ?? 0;
      trackNumber = metadata.trackNumber ?? 0;
      year = metadata.year?.year ?? 0;
      genre = metadata.genres.where((g) => g.trim().isNotEmpty).join(', ');
      coverPath = await _extractEmbeddedCover(path, metadata);
    }

    coverPath ??= await _findSidecarCover(path);

    return Track(
      id: 'local_${stableLocalId(path)}',
      title: title,
      artist: artist,
      album: album,
      albumId: '',
      artistId: '',
      duration: duration,
      trackNumber: trackNumber,
      year: year,
      genre: genre,
      coverArt: coverPath ?? '',
      path: path,
    );
  }

  ({String title, String? artist}) _titleFromFileName(String path) {
    final separator = path.lastIndexOf(Platform.pathSeparator);
    final fileName = path.substring(separator + 1);
    final nameWithoutExt = fileName.contains('.')
        ? fileName.substring(0, fileName.lastIndexOf('.'))
        : fileName;

    // "Artist - Title" is the conventional naming for loose files.
    if (nameWithoutExt.contains(' - ')) {
      final parts = nameWithoutExt.split(' - ');
      if (parts.length >= 2) {
        return (
          title: parts.sublist(1).join(' - ').trim(),
          artist: parts[0].trim(),
        );
      }
    }
    return (title: nameWithoutExt, artist: null);
  }

  Future<String?> _extractEmbeddedCover(
    String path,
    AudioMetadata metadata,
  ) async {
    if (metadata.pictures.isEmpty) return null;

    Picture? chosen;
    for (final picture in metadata.pictures) {
      if (picture.pictureType == PictureType.coverFront) {
        chosen = picture;
        break;
      }
    }
    chosen ??= metadata.pictures.first;
    if (chosen.bytes.isEmpty) return null;

    try {
      final support = await getApplicationSupportDirectory();
      final coverDir = Directory('${support.path}/covers');
      if (!await coverDir.exists()) {
        await coverDir.create(recursive: true);
      }

      final extension = chosen.mimetype.contains('png')
          ? '.png'
          : chosen.mimetype.contains('webp')
          ? '.webp'
          : '.jpg';
      final coverFile = File(
        '${coverDir.path}/${stableLocalId(path)}$extension',
      );
      if (!await coverFile.exists()) {
        await coverFile.writeAsBytes(chosen.bytes, flush: true);
      }
      return coverFile.path;
    } catch (e) {
      // Cache not writable: run without a cover.
      return null;
    }
  }

  Future<String?> _findSidecarCover(String path) async {
    final separator = path.lastIndexOf(Platform.pathSeparator);
    final dirPath = separator > 0 ? path.substring(0, separator) : path;
    final dot = path.lastIndexOf('.');
    final base = path.substring(separator + 1, dot > separator ? dot : null);

    final index = _dirIndex[dirPath] ??= await _indexDirectory(dirPath);

    for (final name in _sidecarCovers) {
      for (final extension in _sidecarCoverExtensions) {
        final hit = index['$name$extension'];
        if (hit != null) return hit;
      }
    }

    // Cover named after the audio file itself: `song.mp3` → `song.jpg`.
    for (final extension in _sidecarCoverExtensions) {
      final hit = index['$base$extension'];
      if (hit != null) return hit;
    }
    return null;
  }

  Future<Map<String, String>> _indexDirectory(String dirPath) async {
    final index = <String, String>{};
    try {
      await for (final entity in Directory(dirPath).list(followLinks: false)) {
        if (entity is File) {
          final name = entity.uri.pathSegments.last;
          index[name.toLowerCase()] = entity.path;
        }
      }
    } catch (e) {
      // Unreadable folder: treat as having no sidecar cover.
    }
    return index;
  }
}

String? _firstNonEmpty(String? value) {
  if (value == null) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

/// Stable per-path id, used for track ids and cover cache file names.
///
/// `String.hashCode` differs between runs, which would orphan the cached
/// cover images on every launch, so hash the path ourselves instead.
String stableLocalId(String path) {
  var hash = 0x811C9DC5;
  for (final unit in path.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  return hash.toRadixString(16).padLeft(8, '0');
}
