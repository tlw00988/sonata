import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sonata/api/api.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalFileRepository repository;

  setUp(() {
    repository = LocalFileRepository();
    SharedPreferences.setMockInitialValues({});
  });

  group('scan directories', () {
    test('first read seeds the platform defaults', () async {
      final dirs = await repository.getScanDirectories();

      expect(dirs, equals(await repository.defaultDirectories()));

      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getStringList(LocalFileRepository.localDirsPrefKey),
        equals(dirs),
      );
    });

    test('stored list round-trips through save and read', () async {
      await repository.saveScanDirectories(['/music/a', '/music/b']);

      expect(await repository.getScanDirectories(), ['/music/a', '/music/b']);
    });

    test('saves normalize paths: trim, strip trailing slash, dedupe', () async {
      final saved = await repository.saveScanDirectories([
        '/a/',
        '/b',
        '/b',
        '  ',
        '/a',
      ]);

      expect(saved, ['/a', '/b']);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList(LocalFileRepository.localDirsPrefKey), [
        '/a',
        '/b',
      ]);
    });

    test('an emptied list stays empty instead of reseeding defaults', () async {
      await repository.saveScanDirectories([]);

      expect(await repository.getScanDirectories(), isEmpty);
    });

    test('read normalizes a list written by hand', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(LocalFileRepository.localDirsPrefKey, [
        '/x/',
        '/x',
        ' /y ',
      ]);

      expect(await repository.getScanDirectories(), ['/x', '/y']);
    });
  });

  group('normalizeDirList', () {
    test('keeps order of first occurrence', () {
      expect(LocalFileRepository.normalizeDirList(['/b', '/a', '/b', '/c']), [
        '/b',
        '/a',
        '/c',
      ]);
    });

    test('drops blanks and trims surrounding whitespace', () {
      expect(
        LocalFileRepository.normalizeDirList(['', '   ', ' /music ', '/']),
        ['/music', '/'],
      );
    });

    test('strips trailing separators but keeps root paths', () {
      expect(LocalFileRepository.normalizeDirList(['/a/', '/a//', '/']), [
        '/a',
        '/',
      ]);
    });
  });
}
