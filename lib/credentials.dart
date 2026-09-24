import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The server password and API key.
///
/// Secrets are kept in the platform secure store — Android KeyStore, Apple
/// Keychain, the system credential store on Linux and Windows — rather than in
/// plain `SharedPreferences`. Values written by a build that predates this
/// class are migrated out of plain preferences on first use, so an existing
/// login survives the upgrade.
///
/// Every call degrades to plain `SharedPreferences` when the secure store is
/// unavailable (for instance a desktop session with no credential service):
/// losing the ability to log in would be worse than storing the secret in the
/// clear, and the fallback keeps the app working. The downgrade is logged so
/// it shows up in `flutter run` output instead of happening silently.
class Credentials {
  Credentials({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const String passwordKey = 'password';
  static const String apiKeyKey = 'api_key';

  final FlutterSecureStorage _storage;
  bool _migrated = false;

  Future<String?> readPassword() => _read(passwordKey);

  Future<String?> readApiKey() => _read(apiKeyKey);

  Future<void> writePassword(String value) => _write(passwordKey, value);

  Future<void> writeApiKey(String value) => _write(apiKeyKey, value);

  /// Forgets both secrets, in the secure store and in plain preferences.
  Future<void> clear() async {
    _migrated = true;
    for (final key in const [passwordKey, apiKeyKey]) {
      try {
        await _storage.delete(key: key);
      } catch (e) {
        debugPrint('Secure store unavailable while deleting $key: $e');
      }
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(passwordKey);
    await prefs.remove(apiKeyKey);
  }

  Future<String?> _read(String key) async {
    await _migrate();
    try {
      final value = await _storage.read(key: key);
      if (value != null) return value;
    } catch (e) {
      debugPrint('Secure store unavailable while reading $key: $e');
    }
    return (await SharedPreferences.getInstance()).getString(key);
  }

  Future<void> _write(String key, String value) async {
    await _migrate();
    final prefs = await SharedPreferences.getInstance();
    if (value.isEmpty) {
      await prefs.remove(key);
      try {
        await _storage.delete(key: key);
      } catch (e) {
        debugPrint('Secure store unavailable while deleting $key: $e');
      }
      return;
    }
    try {
      await _storage.write(key: key, value: value);
      // Never keep a plain copy next to the encrypted one.
      await prefs.remove(key);
    } catch (e) {
      debugPrint('Secure store unavailable while writing $key: $e');
      await prefs.setString(key, value);
    }
  }

  /// Moves secrets a previous version stored in plain preferences into the
  /// secure store. Runs once per instance and leaves the plain value behind
  /// when the move fails, so the login is never lost.
  Future<void> _migrate() async {
    if (_migrated) return;
    _migrated = true;
    final prefs = await SharedPreferences.getInstance();
    for (final key in const [passwordKey, apiKeyKey]) {
      final legacy = prefs.getString(key);
      if (legacy == null || legacy.isEmpty) continue;
      try {
        await _storage.write(key: key, value: legacy);
        await prefs.remove(key);
      } catch (e) {
        debugPrint('Secure store unavailable while migrating $key: $e');
      }
    }
  }
}
