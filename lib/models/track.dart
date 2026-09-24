class Track {
  final String id;
  final String title;
  final String artist;
  final String album;
  final String albumId;
  final String artistId;
  final int duration;
  final int trackNumber;
  final int year;
  final String genre;
  final String coverArt;
  final String path;
  final bool isVideo;

  Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.albumId,
    required this.artistId,
    required this.duration,
    this.trackNumber = 0,
    this.year = 0,
    this.genre = '',
    this.coverArt = '',
    this.path = '',
    this.isVideo = false,
  });

  factory Track.fromJson(Map<String, dynamic> json) {
    return Track(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      artist: json['artist']?.toString() ?? '',
      album: json['album']?.toString() ?? '',
      albumId: json['albumId']?.toString() ?? '',
      artistId: json['artistId']?.toString() ?? '',
      duration: int.tryParse(json['duration']?.toString() ?? '0') ?? 0,
      trackNumber: int.tryParse(json['track']?.toString() ?? '0') ?? 0,
      year: int.tryParse(json['year']?.toString() ?? '0') ?? 0,
      genre: json['genre']?.toString() ?? '',
      coverArt: json['coverArt']?.toString() ?? '',
      path: json['path']?.toString() ?? '',
      isVideo: json['isVideo'] == 'true' || json['isVideo'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'albumId': albumId,
      'artistId': artistId,
      'duration': duration,
      'track': trackNumber,
      'year': year,
      'genre': genre,
      'coverArt': coverArt,
      'path': path,
      'isVideo': isVideo,
    };
  }

  String get formattedDuration {
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }

  /// True when this track plays a file on this device rather than a
  /// server-side song.
  bool get isLocal => path.isNotEmpty && id.startsWith('local_');

  Track copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    String? albumId,
    String? artistId,
    int? duration,
    int? trackNumber,
    int? year,
    String? genre,
    String? coverArt,
    String? path,
    bool? isVideo,
  }) {
    return Track(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      albumId: albumId ?? this.albumId,
      artistId: artistId ?? this.artistId,
      duration: duration ?? this.duration,
      trackNumber: trackNumber ?? this.trackNumber,
      year: year ?? this.year,
      genre: genre ?? this.genre,
      coverArt: coverArt ?? this.coverArt,
      path: path ?? this.path,
      isVideo: isVideo ?? this.isVideo,
    );
  }
}
