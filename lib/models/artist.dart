class Artist {
  final String id;
  final String name;
  final String coverArt;
  final int albumCount;
  final int songCount;

  Artist({
    required this.id,
    required this.name,
    this.coverArt = '',
    this.albumCount = 0,
    this.songCount = 0,
  });

  factory Artist.fromJson(Map<String, dynamic> json) {
    return Artist(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      coverArt: json['coverArt']?.toString() ?? '',
      albumCount: int.tryParse(json['albumCount']?.toString() ?? '0') ?? 0,
      songCount: int.tryParse(json['songCount']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'coverArt': coverArt,
      'albumCount': albumCount,
      'songCount': songCount,
    };
  }
}