import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'auth.dart';
import '../models/models.dart';

class SubsonicClient {
  final Dio _dio;
  final SubsonicAuth _auth;
  final String baseUrl;

  SubsonicClient({required this.baseUrl, required this._auth, Dio? dio})
    : _dio = dio ?? _createDio(baseUrl);

  static Dio _createDio(String baseUrl) {
    return Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 30),
          headers: {'Accept': 'application/json'},
        ),
      )
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (kDebugMode) {
              print('REQUEST[${options.method}] => ${options.uri}');
            }
            handler.next(options);
          },
          onResponse: (response, handler) {
            if (kDebugMode) {
              print(
                'RESPONSE[${response.statusCode}] => ${response.requestOptions.uri}',
              );
            }
            handler.next(response);
          },
          onError: (error, handler) {
            if (kDebugMode) {
              print(
                'ERROR[${error.response?.statusCode}] => ${error.requestOptions.uri}: ${error.message}',
              );
            }
            handler.next(error);
          },
        ),
      );
  }

  Map<String, dynamic> _defaultParams() => {..._auth.authParams, 'f': 'json'};

  Future<Map<String, dynamic>> _get(
    String path, {
    Map<String, dynamic>? queryParams,
  }) async {
    final params = {..._defaultParams(), ...?queryParams};
    final response = await _dio.get(path, queryParameters: params);
    final data = response.data;
    if (data is Map<String, dynamic>) return data;
    // 常见于把网页地址填进来了：返回 200 + HTML。
    throw FormatException(
      '响应不是 JSON，实际是 ${data.runtimeType}'
      '${data is String && data.trim().isNotEmpty ? '：${_clip(data)}' : ''}',
    );
  }

  Future<bool> ping() async => await pingWithReason() == null;

  /// 探测服务器连通性：成功返回 `null`，失败返回一段可以直接放进
  /// 提示框的原因（带请求地址与原始错误细节，方便没有控制台日志的
  /// 构建 —— 比如未签名的 ipa —— 也能定位问题）。
  Future<String?> pingWithReason() async {
    // 地址里不含 query，凭据（t/s/apiKey）绝不进提示框。
    final endpoint = '$baseUrl/rest/ping';
    try {
      final result = await _get('/rest/ping');
      final subsonicResponse = result['subsonic-response'];
      if (subsonicResponse is! Map<String, dynamic>) {
        final keys = result.keys.take(5).join(', ');
        return '$endpoint — not a Subsonic response, got fields: $keys';
      }
      if (subsonicResponse['status'] == 'ok') return null;
      final error = subsonicResponse['error'];
      final code = error is Map ? error['code'] : '?';
      final message = error is Map
          ? error['message']
          : subsonicResponse['status'];
      return '$endpoint — server rejected: $code $message';
    } catch (e) {
      if (kDebugMode) print('Ping failed: $e');
      return '$endpoint — ${describeConnectionError(e)}';
    }
  }

  Future<List<Album>> getAlbums({String? type, int? size, int? offset}) async {
    final result = await _get(
      '/rest/getAlbumList2',
      queryParams: {
        'type': type ?? 'newest',
        if (size != null) 'size': size.toString(),
        if (offset != null) 'offset': offset.toString(),
      },
    );
    final albumsJson =
        result['subsonic-response']?['albumList2']?['album']
            as List<dynamic>? ??
        [];
    return albumsJson
        .map((json) => Album.fromJson(json as Map<String, dynamic>))
        .toList();
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

  Future<List<Track>> getSongs({
    String? genre,
    String? fromYear,
    String? toYear,
    int? size,
    int? offset,
  }) async {
    try {
      final result = await _get(
        '/rest/getRandomSongs',
        queryParams: {
          'genre': ?genre,
          'fromYear': ?fromYear,
          'toYear': ?toYear,
          if (size != null) 'size': size.toString(),
          if (offset != null) 'offset': offset.toString(),
        },
      );
      final songsJson =
          result['subsonic-response']?['randomSongs']?['song']
              as List<dynamic>? ??
          [];
      return songsJson
          .map((json) => Track.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Track>> getSongsByAlbum(String albumId) async {
    try {
      final result = await _get('/rest/getAlbum', queryParams: {'id': albumId});
      final songsJson =
          result['subsonic-response']?['album']?['song'] as List<dynamic>? ??
          [];
      return songsJson
          .map((json) => Track.fromJson(json as Map<String, dynamic>))
          .toList();
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
    final result = await _get(
      '/rest/search2',
      queryParams: {
        'query': query,
        if (artistCount != null) 'artistCount': artistCount.toString(),
        if (albumCount != null) 'albumCount': albumCount.toString(),
        if (songCount != null) 'songCount': songCount.toString(),
        if (offset != null) 'offset': offset.toString(),
      },
    );

    final songsJson =
        result['subsonic-response']?['searchResult2']?['song']
            as List<dynamic>? ??
        [];
    return songsJson
        .map((json) => Track.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<Playlist>> getPlaylists() async {
    final result = await _get('/rest/getPlaylists');
    final playlistsJson =
        result['subsonic-response']?['playlists']?['playlist']
            as List<dynamic>? ??
        [];
    return playlistsJson
        .map((json) => Playlist.fromJson(json as Map<String, dynamic>))
        .toList();
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
    final queryString = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value.toString())}')
        .join('&');
    return '$baseUrl/rest/getCoverArt?$queryString';
  }

  String getStreamUrl(
    String trackId, {
    String? format,
    bool? estimateContentLength,
  }) {
    final params = {..._auth.authParams, 'id': trackId};
    if (format != null) params['format'] = format;
    if (estimateContentLength != null) {
      params['estimateContentLength'] = estimateContentLength.toString();
    }
    final queryString = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value.toString())}')
        .join('&');
    return '$baseUrl/rest/stream?$queryString';
  }

  Future<String?> getLyrics(String artist, String title) async {
    return null;
  }

  Future<String?> getLyricsBySongId(String songId) async {
    try {
      final result = await _get(
        '/rest/getLyricsBySongId',
        queryParams: {'id': songId},
      );
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
          buf.writeln(
            '[${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${(millis ~/ 10).toString().padLeft(2, '0')}]$value',
          );
        }
        return buf.toString();
      } else {
        return lines
            .map((l) => l['value']?.toString() ?? '')
            .where((s) => s.isNotEmpty)
            .join('\n');
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
      final result = await _get(
        '/rest/scrobble',
        queryParams: {'id': id, 'submission': submission.toString()},
      );
      return result['subsonic-response']?['status'] == 'ok';
    } catch (e) {
      return false;
    }
  }

  Future<List<Artist>> getArtists({int? size, int? offset}) async {
    final result = await _get(
      '/rest/getArtists',
      queryParams: {
        if (size != null) 'size': size.toString(),
        if (offset != null) 'offset': offset.toString(),
      },
    );
    final indices =
        result['subsonic-response']?['artists']?['index'] as List<dynamic>? ??
        [];
    final List<Artist> allArtists = [];
    for (final index in indices) {
      final artists = index['artist'] as List<dynamic>? ?? [];
      allArtists.addAll(
        artists.map((json) => Artist.fromJson(json as Map<String, dynamic>)),
      );
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
      final result = await _get(
        '/rest/getArtist',
        queryParams: {'id': artistId},
      );
      final albumsJson =
          result['subsonic-response']?['artist']?['album'] as List<dynamic>? ??
          [];
      return albumsJson
          .map((json) => Album.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Track>> getStarred() async {
    final result = await _get('/rest/getStarred');
    final songsJson =
        result['subsonic-response']?['starred']?['song'] as List<dynamic>? ??
        [];
    return songsJson
        .map((json) => Track.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}

/// 把连接异常翻译成一行人话，直接显示在设置页的提示框里。
///
/// 未签名的 ipa 拿不到控制台日志，所以这里必须给出可辨识的根因：
/// 端口不通 / 超时 / 证书 / 401 / 响应不是 Subsonic 等。
String describeConnectionError(Object e) {
  if (e is DioException) {
    final uri = e.requestOptions.uri;
    final endpoint =
        '${uri.scheme}://${uri.host}'
        '${uri.hasPort ? ':${uri.port}' : ''}${uri.path}';
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return '连接超时（15 秒未响应）：$endpoint —— 服务器地址/端口可能不对，或不在同一网络';
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return '读写超时：$endpoint —— 服务器响应太慢或已挂起';
      case DioExceptionType.badCertificate:
        return 'TLS 证书校验失败：$endpoint —— 自签证书未被信任';
      case DioExceptionType.connectionError:
        final cause = e.error;
        if (cause is SocketException) {
          return '${_describeSocket(cause)}：$endpoint';
        }
        return '无法建立连接：$endpoint —— ${e.message ?? cause ?? '未知原因'}';
      case DioExceptionType.badResponse:
        final status = e.response?.statusCode;
        final body = e.response?.data;
        if (status == 401 || status == 403) {
          return 'HTTP $status：$endpoint —— 用户名或密码/API Key 错误';
        }
        if (status == 404) {
          return 'HTTP 404：$endpoint —— 路径不存在，服务器地址可能少了一段（如 /navidrome）';
        }
        final snippet = body is String
            ? (body.isEmpty ? '' : '，响应：${_clip(body)}')
            : '';
        return 'HTTP ${status ?? '?'}：$endpoint$snippet';
      case DioExceptionType.unknown:
        final cause = e.error;
        if (cause is HandshakeException || cause is CertificateException) {
          return 'TLS 握手/证书失败：$endpoint —— $cause';
        }
        if (cause is SocketException) {
          return '${_describeSocket(cause)}：$endpoint';
        }
        return '${e.message ?? '网络错误'}：$endpoint${cause == null ? '' : ' —— $cause'}';
      case DioExceptionType.cancel:
        return '请求被取消：$endpoint';
      case DioExceptionType.transformTimeout:
        return '响应解析超时：$endpoint —— 服务器响应太慢或已挂起';
    }
  }
  if (e is SocketException) return _describeSocket(e);
  if (e is HandshakeException || e is CertificateException) {
    return 'TLS 握手/证书失败：$e';
  }
  if (e is HttpException) return 'HTTP 异常：$e';
  if (e is FormatException) return '响应格式异常（不是 JSON）：$e';
  return e.toString();
}

String _describeSocket(SocketException e) {
  final code = e.osError?.errorCode;
  final msg = e.osError?.message ?? e.message;
  if (code == 61 || msg.contains('refused')) {
    return '连接被拒绝（端口未开）—— 确认端口号，服务是否已启动';
  }
  if (code == 65 || msg.contains('No route') || msg.contains('unreachable')) {
    return '无法路由到主机 —— 设备不在同一局域网，或 iOS 拒绝了本地网络权限';
  }
  if (code == 8 || msg.contains('nodename') || msg.contains('not known')) {
    return '域名解析失败 —— 主机名写错或需要内网 DNS';
  }
  if (msg.contains('timed out')) return '连接超时 —— 地址不通或被防火墙丢包';
  return '网络错误：$msg${code == null ? '' : '（errno $code）'}';
}

String _clip(String s) {
  final flat = s.replaceAll(RegExp(r'\s+'), ' ').trim();
  return flat.length <= 160 ? flat : '${flat.substring(0, 160)}…';
}
