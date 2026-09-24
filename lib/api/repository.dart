import 'package:sonata/api/api.dart';
import 'package:sonata/models/models.dart';

class MusicRepository {
  final SubsonicClient _client;

  MusicRepository(this._client);

  Future<bool> ping() => _client.ping();

  Future<List<Album>> getAlbums({String? type, int? size, int? offset}) =>
      _client.getAlbums(type: type, size: size, offset: offset);

  Future<Album?> getAlbum(String id) => _client.getAlbum(id);

  Future<List<Track>> getSongs({
    String? genre,
    String? fromYear,
    String? toYear,
    int? size,
    int? offset,
  }) => _client.getSongs(
    genre: genre,
    fromYear: fromYear,
    toYear: toYear,
    size: size,
    offset: offset,
  );

  Future<List<Track>> search({
    required String query,
    int? artistCount,
    int? albumCount,
    int? songCount,
    int? offset,
  }) => _client.search(
    query: query,
    artistCount: artistCount,
    albumCount: albumCount,
    songCount: songCount,
    offset: offset,
  );

  Future<List<Playlist>> getPlaylists() => _client.getPlaylists();

  Future<Playlist?> getPlaylist(String id) => _client.getPlaylist(id);

  String getCoverArtUrl(String coverArtId, {int? size}) =>
      _client.getCoverArtUrl(coverArtId, size: size);

  String getStreamUrl(
    String trackId, {
    String? format,
    bool? estimateContentLength,
  }) => _client.getStreamUrl(
    trackId,
    format: format,
    estimateContentLength: estimateContentLength,
  );

  Future<String?> getLyrics(String artist, String title) =>
      _client.getLyrics(artist, title);

  Future<String?> getLyricsBySongId(String songId) =>
      _client.getLyricsBySongId(songId);

  Future<bool> star(String id) => _client.star(id);

  Future<bool> unstar(String id) => _client.unstar(id);

  Future<bool> scrobble(String id, {bool submission = true}) =>
      _client.scrobble(id, submission: submission);

  Future<List<Artist>> getArtists({int? size, int? offset}) =>
      _client.getArtists(size: size, offset: offset);

  Future<Artist?> getArtist(String id) => _client.getArtist(id);

  Future<List<Album>> getArtistAlbums(String artistId) =>
      _client.getArtistAlbums(artistId);

  Future<List<Track>> getStarred() => _client.getStarred();

  Future<List<Track>> getSongsByAlbum(String albumId) =>
      _client.getSongsByAlbum(albumId);
}
