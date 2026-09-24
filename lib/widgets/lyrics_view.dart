import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class LyricsView extends StatelessWidget {
  final String? lyrics;
  final TextStyle? style;
  final TextStyle? timestampStyle;
  final double lineHeight;
  final EdgeInsetsGeometry? padding;

  const LyricsView({
    super.key,
    this.lyrics,
    this.style,
    this.timestampStyle,
    this.lineHeight = 1.5,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final defaultStyle = TextStyle(
      color: colorScheme.onSurfaceVariant,
      fontSize: 15,
      height: lineHeight,
    );
    final defaultTimestampStyle = TextStyle(
      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
      fontSize: 12,
      fontFamily: 'monospace',
    );

    if (lyrics == null || lyrics!.trim().isEmpty) {
      return Center(
        child: Padding(
          padding: padding ?? const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lyrics_outlined,
                size: 48,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.noLyricsAvailable,
                style: defaultStyle.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final lines = _parseLyrics(lyrics!);

    return SingleChildScrollView(
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: lines.map((line) {
          if (line.isTimestamp) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                line.text,
                style: timestampStyle ?? defaultTimestampStyle,
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(line.text, style: style ?? defaultStyle),
          );
        }).toList(),
      ),
    );
  }

  List<_LyricLine> _parseLyrics(String lyrics) {
    final lines = <_LyricLine>[];
    final regex = RegExp(r'\[(\d{2}:\d{2}\.\d{2,3})\]');

    for (final rawLine in lyrics.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      final matches = regex.allMatches(line);
      if (matches.isNotEmpty) {
        var lastEnd = 0;
        for (final match in matches) {
          if (match.start > lastEnd) {
            final text = line.substring(lastEnd, match.start).trim();
            if (text.isNotEmpty) {
              lines.add(_LyricLine(text: text, isTimestamp: false));
            }
          }
          lines.add(_LyricLine(text: match.group(0)!, isTimestamp: true));
          lastEnd = match.end;
        }
        if (lastEnd < line.length) {
          final text = line.substring(lastEnd).trim();
          if (text.isNotEmpty) {
            lines.add(_LyricLine(text: text, isTimestamp: false));
          }
        }
      } else {
        lines.add(_LyricLine(text: line, isTimestamp: false));
      }
    }
    return lines;
  }
}

class _LyricLine {
  final String text;
  final bool isTimestamp;

  _LyricLine({required this.text, required this.isTimestamp});
}

/// Centered synced lyrics with 50% viewport center scrolling and fade mask.
/// Active lyric scrolls to exactly the vertical center of the viewport.
class CenteredSyncedLyrics extends StatefulWidget {
  final String? lyrics;
  final Duration currentPosition;
  final Color themeColor;
  final bool showTranslations;

  const CenteredSyncedLyrics({
    super.key,
    this.lyrics,
    required this.currentPosition,
    required this.themeColor,
    this.showTranslations = true,
  });

  @override
  State<CenteredSyncedLyrics> createState() => _CenteredSyncedLyricsState();
}

class _CenteredSyncedLyricsState extends State<CenteredSyncedLyrics> {
  final ScrollController _scrollController = ScrollController();
  late List<_SyncedLyricLine> _lines;
  int _activeIndex = -1;

  @override
  void initState() {
    super.initState();
    _lines = _parseSyncedLyrics(widget.lyrics ?? '');
    _updateActiveIndex();
  }

  @override
  void didUpdateWidget(covariant CenteredSyncedLyrics oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lyrics != widget.lyrics) {
      _lines = _parseSyncedLyrics(widget.lyrics ?? '');
      _activeIndex = -1;
      _updateActiveIndex();
    } else {
      _updateActiveIndex();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _updateActiveIndex() {
    final posMs = widget.currentPosition.inMilliseconds;
    int newIndex = -1;

    for (int i = 0; i < _lines.length; i++) {
      if (_lines[i].timeMs <= posMs) {
        newIndex = i;
      } else {
        break;
      }
    }

    if (newIndex != _activeIndex && newIndex >= 0) {
      setState(() => _activeIndex = newIndex);
      _scrollToActive(newIndex);
    }
  }

  void _scrollToActive(int index) {
    if (!_scrollController.hasClients) return;

    // Calculate target offset: position the active line at 50% of viewport
    final viewportHeight = _scrollController.position.viewportDimension;
    final targetOffset = (index * 52.0) - (viewportHeight * 0.45);

    _scrollController.animateTo(
      targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  List<_SyncedLyricLine> _parseSyncedLyrics(String lyrics) {
    final lines = <_SyncedLyricLine>[];
    final regex = RegExp(r'\[(\d{2}):(\d{2})\.(\d{2,3})\]');

    for (final rawLine in lyrics.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      final matches = regex.allMatches(line);
      if (matches.isNotEmpty) {
        var lastEnd = 0;
        String textContent = '';

        for (final match in matches) {
          if (match.start > lastEnd) {
            textContent += line.substring(lastEnd, match.start);
          }

          final minutes = int.parse(match.group(1)!);
          final seconds = int.parse(match.group(2)!);
          final msStr = match.group(3)!;
          final milliseconds = msStr.length == 3
              ? int.parse(msStr)
              : int.parse(msStr) * 10;
          final timeMs = (minutes * 60 + seconds) * 1000 + milliseconds;

          if (textContent.trim().isNotEmpty) {
            lines.add(
              _SyncedLyricLine(text: textContent.trim(), timeMs: timeMs),
            );
          }
          textContent = '';
          lastEnd = match.end;
        }

        if (lastEnd < line.length) {
          textContent += line.substring(lastEnd);
        }
        if (textContent.trim().isNotEmpty) {
          final lastMatch = matches.last;
          final minutes = int.parse(lastMatch.group(1)!);
          final seconds = int.parse(lastMatch.group(2)!);
          final msStr = lastMatch.group(3)!;
          final milliseconds = msStr.length == 3
              ? int.parse(msStr)
              : int.parse(msStr) * 10;
          final timeMs = (minutes * 60 + seconds) * 1000 + milliseconds + 500;
          lines.add(_SyncedLyricLine(text: textContent.trim(), timeMs: timeMs));
        }
      } else if (line.isNotEmpty) {
        lines.add(_SyncedLyricLine(text: line, timeMs: -1));
      }
    }

    lines.sort((a, b) => a.timeMs.compareTo(b.timeMs));
    return lines;
  }

  @override
  Widget build(BuildContext context) {
    if (_lines.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.noLyricsAvailable,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 16,
          ),
        ),
      );
    }

    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black,
            Colors.black,
            Colors.transparent,
          ],
          stops: const [0.0, 0.18, 0.82, 1.0],
        ).createShader(bounds);
      },
      blendMode: BlendMode.dstIn,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 200),
        itemCount: _lines.length,
        itemBuilder: (context, index) {
          final line = _lines[index];
          final isActive = index == _activeIndex;

          return AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            style: TextStyle(
              fontSize: isActive ? 20 : 17,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
              height: 1.6,
              color: isActive
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.35),
              shadows: isActive
                  ? [
                      Shadow(
                        color: Colors.white.withValues(alpha: 0.7),
                        blurRadius: 24,
                      ),
                      Shadow(
                        color: widget.themeColor.withValues(alpha: 0.6),
                        blurRadius: 16,
                      ),
                    ]
                  : null,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(line.text),
            ),
          );
        },
      ),
    );
  }
}

class _SyncedLyricLine {
  final String text;
  final int timeMs;

  _SyncedLyricLine({required this.text, required this.timeMs});
}

class SyncedLyricsView extends StatefulWidget {
  final String? lyrics;
  final Duration currentPosition;
  final TextStyle? style;
  final TextStyle? activeStyle;
  final TextStyle? timestampStyle;
  final double lineHeight;
  final EdgeInsetsGeometry? padding;

  const SyncedLyricsView({
    super.key,
    this.lyrics,
    required this.currentPosition,
    this.style,
    this.activeStyle,
    this.timestampStyle,
    this.lineHeight = 1.5,
    this.padding,
  });

  @override
  State<SyncedLyricsView> createState() => _SyncedLyricsViewState();
}

class _SyncedLyricsViewState extends State<SyncedLyricsView> {
  late final List<_SyncedLine> _syncedLines;
  int _activeIndex = -1;

  @override
  void initState() {
    super.initState();
    _syncedLines = _parseSyncedLyrics(widget.lyrics ?? '');
    _updateActiveIndex();
  }

  @override
  void didUpdateWidget(covariant SyncedLyricsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lyrics != widget.lyrics) {
      _syncedLines.clear();
      _syncedLines.addAll(_parseSyncedLyrics(widget.lyrics ?? ''));
      _activeIndex = -1;
    }
    _updateActiveIndex();
  }

  void _updateActiveIndex() {
    final positionMs = widget.currentPosition.inMilliseconds;
    int newIndex = -1;

    for (int i = 0; i < _syncedLines.length; i++) {
      if (_syncedLines[i].timeMs <= positionMs) {
        newIndex = i;
      } else {
        break;
      }
    }

    if (newIndex != _activeIndex) {
      setState(() {
        _activeIndex = newIndex;
      });
    }
  }

  List<_SyncedLine> _parseSyncedLyrics(String lyrics) {
    final lines = <_SyncedLine>[];
    final regex = RegExp(r'\[(\d{2}):(\d{2})\.(\d{2,3})\]');

    for (final rawLine in lyrics.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      final matches = regex.allMatches(line);
      if (matches.isNotEmpty) {
        var lastEnd = 0;
        String textContent = '';

        for (final match in matches) {
          if (match.start > lastEnd) {
            textContent += line.substring(lastEnd, match.start);
          }

          final minutes = int.parse(match.group(1)!);
          final seconds = int.parse(match.group(2)!);
          final msStr = match.group(3)!;
          final milliseconds = msStr.length == 3
              ? int.parse(msStr)
              : int.parse(msStr) * 10;

          final timeMs = (minutes * 60 + seconds) * 1000 + milliseconds;

          if (textContent.trim().isNotEmpty) {
            lines.add(_SyncedLine(text: textContent.trim(), timeMs: timeMs));
          }
          textContent = '';
          lastEnd = match.end;
        }

        if (lastEnd < line.length) {
          textContent += line.substring(lastEnd);
        }
        if (textContent.trim().isNotEmpty) {
          final lastMatch = matches.last;
          final minutes = int.parse(lastMatch.group(1)!);
          final seconds = int.parse(lastMatch.group(2)!);
          final msStr = lastMatch.group(3)!;
          final milliseconds = msStr.length == 3
              ? int.parse(msStr)
              : int.parse(msStr) * 10;
          final timeMs = (minutes * 60 + seconds) * 1000 + milliseconds + 500;
          lines.add(_SyncedLine(text: textContent.trim(), timeMs: timeMs));
        }
      } else if (line.isNotEmpty) {
        lines.add(_SyncedLine(text: line, timeMs: -1));
      }
    }

    lines.sort((a, b) => a.timeMs.compareTo(b.timeMs));
    return lines;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final defaultStyle = TextStyle(
      color: colorScheme.onSurfaceVariant,
      fontSize: 15,
      height: widget.lineHeight,
    );
    final defaultActiveStyle = TextStyle(
      color: colorScheme.primary,
      fontSize: 16,
      fontWeight: FontWeight.w500,
      height: widget.lineHeight,
    );

    if (_syncedLines.isEmpty) {
      return LyricsView(
        lyrics: widget.lyrics,
        style: widget.style,
        timestampStyle: widget.timestampStyle,
        lineHeight: widget.lineHeight,
        padding: widget.padding,
      );
    }

    return SingleChildScrollView(
      padding:
          widget.padding ??
          const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _syncedLines.asMap().entries.map((entry) {
          final index = entry.key;
          final line = entry.value;
          final isActive = index == _activeIndex;

          return AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: isActive
                ? (widget.activeStyle ?? defaultActiveStyle)
                : (widget.style ?? defaultStyle),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(line.text),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SyncedLine {
  final String text;
  final int timeMs;

  _SyncedLine({required this.text, required this.timeMs});
}
