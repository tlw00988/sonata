import 'dart:io';

import 'package:dio/dio.dart';
import 'package:sonata/api/api.dart';
import 'package:flutter_test/flutter_test.dart';

DioException _dio(
  DioExceptionType type, {
  Object? error,
  int? status,
  Object? data,
}) {
  final options = RequestOptions(
    baseUrl: 'http://192.168.1.10:4533',
    path: '/rest/ping',
    queryParameters: {'u': 'me', 't': 'abcdef0123456789'},
  );
  return DioException(
    requestOptions: options,
    type: type,
    error: error,
    response: status == null
        ? null
        : Response(requestOptions: options, statusCode: status, data: data),
  );
}

void main() {
  group('describeConnectionError', () {
    test('refused socket points at the port', () {
      final msg = describeConnectionError(
        const SocketException(
          'Connection refused',
          osError: OSError('Connection refused', 61),
        ),
      );
      expect(msg, contains('端口未开'));
    });

    test('DNS failure points at the hostname', () {
      final msg = describeConnectionError(
        const SocketException(
          'Failed host lookup: nas.lan',
          osError: OSError('No address associated with hostname', 8),
        ),
      );
      expect(msg, contains('域名解析失败'));
    });

    test('connection timeout is not reported as a credential problem', () {
      final msg = describeConnectionError(
        _dio(DioExceptionType.connectionTimeout),
      );
      expect(msg, contains('连接超时'));
      expect(msg, contains('http://192.168.1.10:4533/rest/ping'));
    });

    test('404 distinguishes a missing path suffix', () {
      final msg = describeConnectionError(
        _dio(DioExceptionType.badResponse, status: 404),
      );
      expect(msg, contains('HTTP 404'));
      expect(msg, contains('路径不存在'));
    });

    test('401 blames credentials', () {
      final msg = describeConnectionError(
        _dio(DioExceptionType.badResponse, status: 401),
      );
      expect(msg, contains('用户名或密码'));
    });

    test('socket cause wrapped by Dio still gets the errno wording', () {
      final msg = describeConnectionError(
        _dio(
          DioExceptionType.connectionError,
          error: const SocketException(
            'No route to host',
            osError: OSError('No route to host', 65),
          ),
        ),
      );
      expect(msg, contains('无法路由到主机'));
      expect(msg, contains('本地网络权限'));
    });

    test('credentials never leak into the message', () {
      for (final msg in [
        describeConnectionError(_dio(DioExceptionType.connectionTimeout)),
        describeConnectionError(
          _dio(DioExceptionType.badResponse, status: 500),
        ),
      ]) {
        expect(msg, contains('http://192.168.1.10:4533/rest/ping'));
        expect(msg, isNot(contains('abcdef0123456789')));
        expect(msg, isNot(contains('u=me')));
      }
    });

    test('unknown fallback keeps the original detail', () {
      expect(describeConnectionError(StateError('boom')), contains('boom'));
    });
  });
}
