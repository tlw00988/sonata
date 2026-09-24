import 'track.dart';

class Playlist {
  final String id;
  final String name;
  final String comment;
  final String owner;
  final bool isPublic;
  final String coverArt;
  final int songCount;
  final int duration;
  final DateTime created;
  final DateTime changed;

  /// The songs this playlist contains.
  ///
  /// Subsonic only returns them under `entry` for `getPlaylist`, so a playlist
  /// coming from `getPlaylists` has an empty list here.
  final List<Track> tracks;

  Playlist({
    required this.id,
    required this.name,
    this.comment = '',
    this.owner = '',
    this.isPublic = false,
    this.coverArt = '',
    this.songCount = 0,
    this.duration = 0,
    required this.created,
    required this.changed,
    this.tracks = const [],
  });

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      comment: json['comment']?.toString() ?? '',
      owner: json['owner']?.toString() ?? '',
      isPublic: json['public'] == 'true' || json['public'] == true,
      coverArt: json['coverArt']?.toString() ?? '',
      songCount: int.tryParse(json['songCount']?.toString() ?? '0') ?? 0,
      duration: int.tryParse(json['duration']?.toString() ?? '0') ?? 0,
      created:
          DateTime.tryParse(json['created']?.toString() ?? '') ??
          DateTime.now(),
      changed:
          DateTime.tryParse(json['changed']?.toString() ?? '') ??
          DateTime.now(),
      tracks: (json['entry'] as List<dynamic>? ?? [])
          .map((item) => Track.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'comment': comment,
      'owner': owner,
      'public': isPublic,
      'coverArt': coverArt,
      'songCount': songCount,
      'duration': duration,
      'created': created.toIso8601String(),
      'changed': changed.toIso8601String(),
      'entry': tracks.map((track) => track.toJson()).toList(),
    };
  }
}
