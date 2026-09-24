class Album {
  final String id;
  final String name;
  final String artist;
  final String artistId;
  final int songCount;
  final int duration;
  final String coverArt;
  final int year;
  final String genre;

  Album({
    required this.id,
    required this.name,
    required this.artist,
    required this.artistId,
    this.songCount = 0,
    this.duration = 0,
    this.coverArt = '',
    this.year = 0,
    this.genre = '',
  });

  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      artist: json['artist']?.toString() ?? '',
      artistId: json['artistId']?.toString() ?? '',
      songCount: int.tryParse(json['songCount']?.toString() ?? '0') ?? 0,
      duration: int.tryParse(json['duration']?.toString() ?? '0') ?? 0,
      coverArt: json['coverArt']?.toString() ?? '',
      year: int.tryParse(json['year']?.toString() ?? '0') ?? 0,
      genre: json['genre']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'artist': artist,
      'artistId': artistId,
      'songCount': songCount,
      'duration': duration,
      'coverArt': coverArt,
      'year': year,
      'genre': genre,
    };
  }
}
