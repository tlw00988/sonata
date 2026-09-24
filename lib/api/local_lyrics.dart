import 'dart:convert';
import 'dart:io';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:charset/charset.dart';

/// Locates the sidecar lyrics file that belongs to [audioPath].
///
/// A track `song.mp3` matches `song.lrc` in the same folder. The lookup is
/// case-insensitive because these files are often renamed by hand, and it
/// also considers the audio file's own extensions (`.lrc.mp3` style names).
String? findLyricsFile(String audioPath) {
  try {
    final file = File(audioPath);
    final dir = file.parent;
    final dot = file.path.lastIndexOf('.');
    if (dot <= 0) return null;

    final base = file.path.substring(
      file.path.lastIndexOf(Platform.pathSeparator) + 1,
      dot,
    );
    final entries = dir.listSync(followLinks: false);
    for (final entry in entries) {
      if (entry is! File) continue;
      final name = entry.uri.pathSegments.last;
      final entryDot = name.lastIndexOf('.');
      if (entryDot <= 0) continue;
      if (name.substring(entryDot).toLowerCase() != '.lrc') continue;
      if (name.substring(0, entryDot).toLowerCase() == base.toLowerCase()) {
        return entry.path;
      }
    }
  } catch (_) {
    // Unreadable folder: no sidecar lyrics.
  }
  return null;
}

/// Reads the lyrics for a local audio file.
///
/// Sidecar `.lrc` files win over lyrics embedded in the audio tags.
/// Returns `null` when the file carries no usable lyrics.
Future<String?> loadLocalLyrics(String audioPath) async {
  final lrcPath = findLyricsFile(audioPath);
  if (lrcPath != null) {
    try {
      final bytes = await File(lrcPath).readAsBytes();
      final text = decodeLyricBytes(bytes);
      final normalized = normalizeLrc(text);
      if (normalized.trim().isNotEmpty) return normalized;
    } catch (_) {
      // Fall through to embedded lyrics.
    }
  }

  try {
    final file = File(audioPath);
    if (!await file.exists()) return null;
    final metadata = readMetadata(file, getImage: false);
    final embedded = metadata.lyrics;
    if (embedded != null && embedded.trim().isNotEmpty) {
      return normalizeLrc(embedded);
    }
  } catch (_) {
    // Tags unreadable: no embedded lyrics.
  }
  return null;
}

/// Decodes lyric bytes, honouring the encodings real-world `.lrc` files use.
String decodeLyricBytes(List<int> bytes) {
  if (bytes.isEmpty) return '';

  // UTF-16 with a byte order mark.
  if (bytes.length >= 2) {
    if (bytes[0] == 0xFF && bytes[1] == 0xFE) return utf16.decode(bytes);
    if (bytes[0] == 0xFE && bytes[1] == 0xFF) return utf16.decode(bytes);
  }

  // UTF-8 with optional BOM.
  var offset = 0;
  if (bytes.length >= 3 &&
      bytes[0] == 0xEF &&
      bytes[1] == 0xBB &&
      bytes[2] == 0xBF) {
    offset = 3;
  }
  try {
    return utf8.decode(bytes.sublist(offset));
  } on FormatException {
    // Not UTF-8: fall back to GBK, the usual encoding of Chinese lyrics.
    try {
      return gbk.decode(bytes, allowMalformed: true);
    } catch (_) {
      return utf8.decode(bytes, allowMalformed: true);
    }
  }
}

final _tagLine = RegExp(r'^\[([A-Za-z#][A-Za-z0-9_]*):(.*)\]$');
final _timeTag = RegExp(r'\[(\d{1,3}):(\d{1,2})(?:[.:](\d{1,4}))?\]');
final _hourTimeTag = RegExp(
  r'\[(\d{1,3}):(\d{1,2}):(\d{1,2})(?:[.:](\d{1,4}))?\]',
);

/// Reworks raw lyrics into the `[mm:ss.xx]` form the player parses.
///
/// Handles the format drift found in real files: `[mm:ss]` tags without a
/// fraction, one- or four-digit fractions, hour-style tags, `[offset:...]`
/// shifts, and drops metadata tags such as `[ar:]` / `[ti:]`.
String normalizeLrc(String raw) {
  var offsetMs = 0;
  final out = <String>[];

  for (final line in raw.split(RegExp(r'\r\n|\r|\n'))) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) continue;

    final tag = _tagLine.firstMatch(trimmed);
    if (tag != null) {
      final key = tag.group(1)!.toLowerCase();
      if (key == 'offset') {
        offsetMs = int.tryParse(tag.group(2)!.trim()) ?? 0;
      }
      continue;
    }

    if (!_timeTag.hasMatch(trimmed) && !_hourTimeTag.hasMatch(trimmed)) {
      out.add(trimmed);
      continue;
    }
    out.add(_shiftTimes(trimmed, offsetMs));
  }

  return out.join('\n');
}

String _shiftTimes(String line, int offsetMs) {
  // Hour-style tags are rewritten first so the offset is applied exactly
  // once by the second pass, which then sees a plain [mm:ss] tag.
  final withoutHours = line.replaceAllMapped(_hourTimeTag, (m) {
    final hours = int.parse(m.group(1)!);
    final minutes = int.parse(m.group(2)!);
    final seconds = int.parse(m.group(3)!);
    final totalMs =
        ((hours * 60 + minutes) * 60 + seconds) * 1000 +
        _fractionMs(m.group(4));
    return _formatTimeTag(totalMs);
  });

  return withoutHours.replaceAllMapped(_timeTag, (m) {
    final minutes = int.parse(m.group(1)!);
    final seconds = int.parse(m.group(2)!);
    final totalMs = (minutes * 60 + seconds) * 1000 + _fractionMs(m.group(3));
    return _formatTimeTag(totalMs - offsetMs);
  });
}

int _fractionMs(String? fraction) {
  if (fraction == null || fraction.isEmpty) return 0;
  final padded = fraction.length >= 3
      ? fraction.substring(0, 3)
      : fraction.padRight(3, '0');
  return int.tryParse(padded) ?? 0;
}

String _formatTimeTag(int totalMs) {
  final clamped = totalMs < 0 ? 0 : totalMs;
  final minutes = clamped ~/ 60000;
  final seconds = (clamped ~/ 1000) % 60;
  final millis = clamped % 1000;
  final mm = minutes.toString().padLeft(2, '0');
  final ss = seconds.toString().padLeft(2, '0');
  final mmm = millis.toString().padLeft(3, '0');
  return '[$mm:$ss.$mmm]';
}
