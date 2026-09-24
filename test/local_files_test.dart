import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:sonata/api/api.dart';

void main() {
  group('normalizeLrc', () {
    test('keeps well-formed timestamps', () {
      const input = '[00:12.34]hello\n[01:02.345]world';
      expect(normalizeLrc(input), '[00:12.340]hello\n[01:02.345]world');
    });

    test('pads timestamps that carry no fraction', () {
      expect(normalizeLrc('[00:12]hello'), '[00:12.000]hello');
    });

    test('drops metadata tags', () {
      const input = '[ar:Someone]\n[ti:A Song]\n[00:01.00]lyric';
      expect(normalizeLrc(input), '[00:01.000]lyric');
    });

    test('applies the offset tag', () {
      // A positive offset shifts lyrics earlier.
      expect(normalizeLrc('[offset:+500]\n[00:10.000]a'), '[00:09.500]a');
      expect(normalizeLrc('[offset:-500]\n[00:10.000]a'), '[00:10.500]a');
    });

    test('clamps an offset that would produce a negative time', () {
      expect(normalizeLrc('[offset:+60000]\n[00:10.000]a'), '[00:00.000]a');
    });

    test('converts hour-style tags into plain minutes', () {
      expect(normalizeLrc('[00:01:02.5]a'), '[01:02.500]a');
    });

    test('applies the offset only once to hour-style tags', () {
      expect(normalizeLrc('[offset:+500]\n[00:01:02.500]a'), '[01:02.000]a');
    });

    test('leaves untimed lines untouched', () {
      expect(normalizeLrc('just some text'), 'just some text');
    });

    test('normalizes CRLF and blank lines', () {
      expect(
        normalizeLrc('[00:01.00]a\r\n\r\n[00:02.00]b'),
        '[00:01.000]a\n[00:02.000]b',
      );
    });
  });

  group('decodeLyricBytes', () {
    test('decodes UTF-8', () {
      expect(decodeLyricBytes(utf8.encode('你好')), '你好');
    });

    test('decodes UTF-8 with a BOM', () {
      final bytes = [0xEF, 0xBB, 0xBF, ...utf8.encode('你好')];
      expect(decodeLyricBytes(bytes), '你好');
    });

    test('decodes UTF-16 LE with a BOM', () {
      // "你好": 你 = U+4F60 -> 60 4F, 好 = U+597D -> 7D 59 (little endian).
      final bytes = [0xFF, 0xFE, 0x60, 0x4F, 0x7D, 0x59];
      expect(decodeLyricBytes(bytes), '你好');
    });

    test('falls back to GBK for non-UTF-8 bytes', () {
      // GBK encoding of "你好".
      final bytes = [0xC4, 0xE3, 0xBA, 0xC3];
      expect(decodeLyricBytes(bytes), '你好');
    });
  });

  group('findLyricsFile', () {
    late Directory dir;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('lrc_test');
    });

    tearDown(() async {
      if (await dir.exists()) await dir.delete(recursive: true);
    });

    test('finds a sidecar lrc with the same base name', () async {
      final audio = File('${dir.path}/song.mp3');
      final lrc = File('${dir.path}/song.lrc');
      await audio.writeAsBytes(const [0]);
      await lrc.writeAsString('[00:01.00]a');

      expect(findLyricsFile(audio.path), lrc.path);
    });

    test('matches case-insensitively', () async {
      final audio = File('${dir.path}/Song.MP3');
      final lrc = File('${dir.path}/SONG.lrc');
      await audio.writeAsBytes(const [0]);
      await lrc.writeAsString('[00:01.00]a');

      expect(findLyricsFile(audio.path), lrc.path);
    });

    test('returns null when no sidecar exists', () async {
      final audio = File('${dir.path}/lonely.mp3');
      await audio.writeAsBytes(const [0]);

      expect(findLyricsFile(audio.path), isNull);
    });

    test('does not match a different track', () async {
      final audio = File('${dir.path}/song.mp3');
      await audio.writeAsBytes(const [0]);
      await File('${dir.path}/other.lrc').writeAsString('[00:01.00]a');

      expect(findLyricsFile(audio.path), isNull);
    });
  });

  group('stableLocalId', () {
    test('is stable for the same path', () {
      expect(stableLocalId('/a/b/c.mp3'), stableLocalId('/a/b/c.mp3'));
    });

    test('differs for different paths', () {
      expect(stableLocalId('/a/b/c.mp3'), isNot(stableLocalId('/a/b/d.mp3')));
    });

    test('produces a fixed-width hex string', () {
      expect(stableLocalId('x'), matches(RegExp(r'^[0-9a-f]{8}$')));
    });
  });

  group('trackFromFile', () {
    late Directory dir;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('meta_test');
    });

    tearDown(() async {
      if (await dir.exists()) await dir.delete(recursive: true);
    });

    test('reads ID3 tags instead of guessing from the file name', () async {
      final file = File('${dir.path}/Wrong Name.mp3');
      await file.writeAsBytes(
        _mp3WithTag(
          title: 'Real Title',
          artist: 'Real Artist',
          album: 'Real Album',
        ),
      );

      final track = await LocalFileRepository().trackFromFile(file.path);

      expect(track, isNotNull);
      expect(track!.title, 'Real Title');
      expect(track.artist, 'Real Artist');
      expect(track.album, 'Real Album');
      expect(track.isLocal, isTrue);
    });

    test('falls back to the file name when tags are missing', () async {
      final file = File('${dir.path}/Artist - Title.mp3');
      await file.writeAsBytes(_mp3WithoutTags());

      final track = await LocalFileRepository().trackFromFile(
        file.path,
        unknownArtist: 'Unknown Artist',
        unknownAlbum: 'Unknown Album',
      );

      expect(track, isNotNull);
      expect(track!.title, 'Title');
      expect(track.artist, 'Artist');
      expect(track.album, 'Unknown Album');
    });

    test('returns null for a missing file', () async {
      final track = await LocalFileRepository().trackFromFile(
        '${dir.path}/nope.mp3',
      );
      expect(track, isNull);
    });
  });
}

/// Builds a minimal MP3 carrying an ID3v2.3 tag plus one MPEG frame.
List<int> _mp3WithTag({
  required String title,
  required String artist,
  required String album,
}) {
  return [
    ..._id3v2Tag([
      _textFrame('TIT2', title),
      _textFrame('TPE1', artist),
      _textFrame('TALB', album),
    ]),
    ..._mpegFrame(),
  ];
}

/// A bare MPEG frame with no ID3 tag, so names fall back to the file name.
List<int> _mp3WithoutTags() => _mpegFrame();

List<int> _mpegFrame() {
  // MPEG-1 Layer III, 128 kbps, 44.1 kHz, no padding: a valid frame header
  // followed by enough zeroed payload for the size computation.
  final header = [0xFF, 0xFB, 0x90, 0x00];
  return [...header, ...List<int>.filled(413, 0)];
}

List<int> _id3v2Tag(List<List<int>> frames) {
  final payload = frames.expand((f) => f).toList();
  return [
    ...ascii.encode('ID3'),
    0x03, 0x00, // version 2.3
    0x00, // flags
    ..._syncsafe(payload.length),
    ...payload,
  ];
}

List<int> _textFrame(String id, String text) {
  final body = [0x00, ...latin1.encode(text)]; // encoding: ISO-8859-1
  return [
    ...ascii.encode(id),
    ..._be32(body.length),
    0x00, 0x00, // frame flags
    ...body,
  ];
}

List<int> _syncsafe(int value) => [
  (value >> 21) & 0x7F,
  (value >> 14) & 0x7F,
  (value >> 7) & 0x7F,
  value & 0x7F,
];

List<int> _be32(int value) => [
  (value >> 24) & 0xFF,
  (value >> 16) & 0xFF,
  (value >> 8) & 0xFF,
  value & 0xFF,
];
