import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/models.dart';

class LocalFileRepository {
  static const List<String> _audioExtensions = [
    '.mp3', '.flac', '.wav', '.ogg', '.m4a', '.aac', '.opus', '.wma'
  ];

  Future<List<Track>> scanForAudioFiles() async {
    final tracks = <Track>[];
    
    // Get common music directories
    final directories = await _getMusicDirectories();
    
    for (final dir in directories) {
      if (await dir.exists()) {
        await _scanDirectory(dir, tracks);
      }
    }
    
    return tracks;
  }

  Future<List<Directory>> _getMusicDirectories() async {
    final directories = <Directory>[];
    
    // Android/iOS music directory
    try {
      final extDir = await getExternalStorageDirectory();
      if (extDir != null) {
        directories.add(Directory('${extDir.path}/Music'));
        directories.add(Directory('${extDir.path}/Download'));
      }
    } catch (e) {
      // Ignore
    }
    
    // Windows
    try {
      final userProfile = Platform.environment['USERPROFILE'];
      if (userProfile != null) {
        directories.add(Directory('$userProfile\\Music'));
        directories.add(Directory('$userProfile\\Downloads'));
        directories.add(Directory('$userProfile\\Desktop'));
      }
    } catch (e) {
      // Ignore
    }

    // Linux/macOS
    try {
      final homeDir = Platform.environment['HOME'] ?? '';
      if (homeDir.isNotEmpty) {
        directories.add(Directory('$homeDir/Music'));
        directories.add(Directory('$homeDir/Downloads'));
      }
    } catch (e) {
      // Ignore
    }
    
    return directories;
  }

  Future<void> _scanDirectory(Directory dir, List<Track> tracks) async {
    try {
      await for (final entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          final extension = '.${entity.path.split('.').last.toLowerCase()}';
          if (_audioExtensions.contains(extension)) {
            final track = await _createTrackFromFile(entity);
            if (track != null) {
              tracks.add(track);
            }
          }
        }
      }
    } catch (e) {
      // Ignore permission errors
    }
  }

  Future<Track?> _createTrackFromFile(File file) async {
    try {
      final fileName = file.path.split('/').last;
      final nameWithoutExt = fileName.substring(0, fileName.lastIndexOf('.'));
      
      // Try to parse "Artist - Title" format
      String title = nameWithoutExt;
      String artist = 'Unknown Artist';
      String album = 'Unknown Album';
      
      if (nameWithoutExt.contains(' - ')) {
        final parts = nameWithoutExt.split(' - ');
        if (parts.length >= 2) {
          artist = parts[0].trim();
          title = parts.sublist(1).join(' - ').trim();
        }
      }
      
      return Track(
        id: 'local_${file.path.hashCode}',
        title: title,
        artist: artist,
        album: album,
        albumId: '',
        artistId: '',
        duration: 0, // Will be filled by audio player
        coverArt: '',
        path: file.path,
      );
    } catch (e) {
      return null;
    }
  }

  Future<File?> pickAudioFile() async {
    // This would use file_picker package in a real implementation
    // For now, return null
    return null;
  }

  Future<List<Track>> scanDirectory(String dirPath) async {
    final tracks = <Track>[];
    final dir = Directory(dirPath);
    if (await dir.exists()) {
      await _scanDirectory(dir, tracks);
    }
    return tracks;
  }
}