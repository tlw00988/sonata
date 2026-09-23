import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'auth.dart';
import '../models/models.dart';

class SubsonicClient {
  final Dio _dio;
  final SubsonicAuth _auth;
  final String baseUrl;

  SubsonicClient({
    required this.baseUrl,
    required SubsonicAuth auth,
    Dio? dio,
  })  : _auth = auth,
        _dio = dio ?? _createDio(baseUrl);

  static Dio _createDio(String baseUrl) {
    return Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Accept': 'application/json',
        },
      ),
    )..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (kDebugMode) {
              print('REQUEST[${options.method}] => ${options.uri}');
            }
            handler.next(options);
          },
          onResponse: (response, handler) {
            if (kDebugMode) {
              print('RESPONSE[${response.statusCode}] => ${response.requestOptions.uri}');
            }
            handler.next(response);
          },
          onError: (error, handler) {
            if (kDebugMode) {
              print('ERROR[${error.response?.statusCode}] => ${error.requestOptions.uri}: ${error.message}');
            }
            handler.next(error);
          },
        ),
      );
  }

  Map<String, dynamic> _defaultParams() => {
        ..._auth.authParams,
        'f': 'json',
      };

  Future<Map<String, dynamic>> _get(String path, {Map<String, dynamic>? queryParams}) async {
    final params = {..._defaultParams(), ...?queryParams};
    final response = await _dio.get(path, queryParameters: params);
    final data = response.data;
    if (data is Map<String, dynamic>) return data;
    throw FormatException('Unexpected response type: ${data.runtimeType}');
  }

  Future<bool> ping() async {
    try {
      final result = await _get('/rest/ping');
      final subsonicResponse = result['subsonic-response'];
      if (subsonicResponse is Map<String, dynamic>) {
        return subsonicResponse['status'] == 'ok';
      }
      return false;
    } catch (e) {
      if (kDebugMode) print('Ping failed: $e');
      return false;
    }
  }

  Future<List<Album>> getAlbums({String? type, int? size, int? offset}) async {
    final result = await _get('/rest/getAlbumList2', queryParams: {
      'type': type ?? 'newest',
      if (size != null) 'size': size.toString(),
      if (offset != null) 'offset': offset.toString(),
    });
    final albumsJson = result['subsonic-response']?['albumList2']?['album'] as List<dynamic>? ?? [];
    return albumsJson.map((json) => Album.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<Album?> getAlbum(String id) async {
    try {
      final result = await _get('/rest/getAlbum', queryParams: {'id': id});
      final albumJson = result['subsonic-response']?['album'];
      if (albumJson != null) {
        return Album.fromJson(albumJson as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<Track>> getSongs({String? genre, String? fromYear, String? toYear, int? size, int? offset}) async {
    try {
      final result = await _get('/rest/getRandomSongs', queryParams: {
        if (genre != null) 'genre': genre,
        if (fromYear != null) 'fromYear': fromYear,
        if (toYear != null) 'toYear': toYear,
        if (size != null) 'size': size.toString(),
        if (offset != null) 'offset': offset.toString(),
      });
      final songsJson = result['subsonic-response']?['randomSongs']?['song'] as List<dynamic>? ?? [];
      return songsJson.map((json) => Track.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Track>> getSongsByAlbum(String albumId) async {
    try {
      final result = await _get('/rest/getAlbum', queryParams: {'id': albumId});
      final songsJson = result['subsonic-response']?['album']?['song'] as List<dynamic>? ?? [];
      return songsJson.map((json) => Track.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Track>> search({
    required String query,
    int? artistCount,
    int? albumCount,
    int? songCount,
    int? offset,
  }) async {
    final result = await _get('/rest/search2', queryParams: {
      'query': query,
      if (artistCount != null) 'artistCount': artistCount.toString(),
      if (albumCount != null) 'albumCount': albumCount.toString(),
      if (songCount != null) 'songCount': songCount.toString(),
      if (offset != null) 'offset': offset.toString(),
    });
    
    final songsJson = result['subsonic-response']?['searchResult2']?['song'] as List<dynamic>? ?? [];
    return songsJson.map((json) => Track.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<List<Playlist>> getPlaylists() async {
    final result = await _get('/rest/getPlaylists');
    final playlistsJson = result['subsonic-response']?['playlists']?['playlist'] as List<dynamic>? ?? [];
    return playlistsJson.map((json) => Playlist.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<Playlist?> getPlaylist(String id) async {
    try {
      final result = await _get('/rest/getPlaylist', queryParams: {'id': id});
      final playlistJson = result['subsonic-response']?['playlist'];
      if (playlistJson != null) {
        return Playlist.fromJson(playlistJson as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  String getCoverArtUrl(String coverArtId, {int? size}) {
    final params = {..._auth.authParams, 'id': coverArtId};
    if (size != null) params['size'] = size.toString();
    final queryString = params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value.toString())}').join('&');
    return '$baseUrl/rest/getCoverArt?$queryString';
  }

  String getStreamUrl(String trackId, {String? format, bool? estimateContentLength}) {
    final params = {..._auth.authParams, 'id': trackId};
    if (format != null) params['format'] = format;
    if (estimateContentLength != null) params['estimateContentLength'] = estimateContentLength.toString();
    final queryString = params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value.toString())}').join('&');
    return '$baseUrl/rest/stream?$queryString';
  }

  Future<String?> getLyrics(String artist, String title) async {
    return null;
  }

  Future<String?> getLyricsBySongId(String songId) async {
    try {
      final result = await _get('/rest/getLyricsBySongId', queryParams: {
        'id': songId,
      });
      final lyricsList = result['subsonic-response']?['lyricsList'];
      if (lyricsList == null) return null;

      final structured = lyricsList['structuredLyrics'] as List<dynamic>?;
      if (structured == null || structured.isEmpty) return null;

      final first = structured[0] as Map<String, dynamic>;
      final synced = first['synced'] == true;
      final lines = first['line'] as List<dynamic>?;

      if (lines == null || lines.isEmpty) return null;

      if (synced) {
        final buf = StringBuffer();
        for (final line in lines) {
          final startMs = (line['start'] as num?)?.toInt() ?? 0;
          final value = line['value']?.toString() ?? '';
          final minutes = startMs ~/ 60000;
          final seconds = (startMs % 60000) ~/ 1000;
          final millis = startMs % 1000;
          buf.writeln('[${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${(millis ~/ 10).toString().padLeft(2, '0')}]$value');
        }
        return buf.toString();
      } else {
        return lines.map((l) => l['value']?.toString() ?? '').where((s) => s.isNotEmpty).join('\n');
      }
    } catch (e) {
      return null;
    }
  }

  Future<bool> star(String id) async {
    try {
      final result = await _get('/rest/star', queryParams: {'id': id});
      return result['subsonic-response']?['status'] == 'ok';
    } catch (e) {
      return false;
    }
  }

  Future<bool> unstar(String id) async {
    try {
      final result = await _get('/rest/unstar', queryParams: {'id': id});
      return result['subsonic-response']?['status'] == 'ok';
    } catch (e) {
      return false;
    }
  }

  Future<bool> scrobble(String id, {bool submission = true}) async {
    try {
      final result = await _get('/rest/scrobble', queryParams: {
        'id': id,
        'submission': submission.toString(),
      });
      return result['subsonic-response']?['status'] == 'ok';
    } catch (e) {
      return false;
    }
  }

  Future<List<Artist>> getArtists({int? size, int? offset}) async {
    final result = await _get('/rest/getArtists', queryParams: {
      if (size != null) 'size': size.toString(),
      if (offset != null) 'offset': offset.toString(),
    });
    final indices = result['subsonic-response']?['artists']?['index'] as List<dynamic>? ?? [];
    final List<Artist> allArtists = [];
    for (final index in indices) {
      final artists = index['artist'] as List<dynamic>? ?? [];
      allArtists.addAll(artists.map((json) => Artist.fromJson(json as Map<String, dynamic>)));
    }
    return allArtists;
  }

  Future<Artist?> getArtist(String id) async {
    try {
      final result = await _get('/rest/getArtist', queryParams: {'id': id});
      final artistJson = result['subsonic-response']?['artist'];
      if (artistJson != null) {
        return Artist.fromJson(artistJson as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<Album>> getArtistAlbums(String artistId) async {
    try {
      final result = await _get('/rest/getArtist', queryParams: {'id': artistId});
      final albumsJson = result['subsonic-response']?['artist']?['album'] as List<dynamic>? ?? [];
      return albumsJson.map((json) => Album.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Track>> getStarred() async {
    final result = await _get('/rest/getStarred');
    final songsJson = result['subsonic-response']?['starred']?['song'] as List<dynamic>? ?? [];
    return songsJson.map((json) => Track.fromJson(json as Map<String, dynamic>)).toList();
  }
}