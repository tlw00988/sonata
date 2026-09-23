import 'package:crypto/crypto.dart';
import 'dart:convert';

class SubsonicAuth {
  final String username;
  final String password;
  final String token;
  final String salt;
  final String? apiKey;
  final String version = '1.16.1';
  final String clientName = 'flutter_music_player';

  factory SubsonicAuth({
    required String username,
    String password = '',
    String? apiKey,
    String? token,
    String? salt,
  }) {
    final actualSalt = salt ?? _generateSalt();
    final actualToken = token ?? _generateToken(password, actualSalt);
    return SubsonicAuth._(
      username: username,
      password: password,
      apiKey: apiKey,
      token: actualToken,
      salt: actualSalt,
    );
  }

  SubsonicAuth._({
    required this.username,
    required this.password,
    this.apiKey,
    required this.token,
    required this.salt,
  });

  static String _generateSalt() {
    final random = DateTime.now().millisecondsSinceEpoch.toString();
    final bytes = utf8.encode(random);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 8);
  }

  static String _generateToken(String password, String salt) {
    final bytes = utf8.encode('$password$salt');
    final digest = md5.convert(bytes);
    return digest.toString();
  }

  Map<String, String> get authParams => {
    if (apiKey != null) ...{
      'apiKey': apiKey!,
    } else ...{
      'u': username,
      't': token,
      's': salt,
    },
    'v': version.toString(),
    'c': clientName,
  };
}
