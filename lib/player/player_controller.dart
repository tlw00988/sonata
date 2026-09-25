import 'dart:async';
import 'dart:ui' show Color;
import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart' as mk;
import 'player_state.dart';
import '../models/models.dart';
import '../api/api.dart';
import '../main.dart' show audioHandler;

class PlayerController extends ChangeNotifier {
  late final mk.Player _player;
  final PlayerState _state;

  MusicRepository? _repository;

  /// 封面取色结果缓存，key 是已经解析好的封面地址。
  ///
  /// 循环播放回到同一首时直接复用上次的颜色（主题色继承），
  /// 取色失败不写缓存，下一次播放同一封面时会自动重试。
  final Map<String, Color?> _coverColorCache = {};

  /// 自增令牌，用于丢弃已经切歌之后才返回的过期取色结果。
  int _themeColorRequest = 0;

  PlayerState get state => _state;

  PlayerController({PlayerState? state}) : _state = state ?? PlayerState() {
    mk.MediaKit.ensureInitialized();
    _player = mk.Player();
    _setupListeners();
    audioHandler.bind(
      _player,
      _state,
      _repository,
      onNext: playNext,
      onPrevious: playPrevious,
    );
  }

  void setRepository(MusicRepository repository) {
    _repository = repository;
    audioHandler.bind(
      _player,
      _state,
      _repository,
      onNext: playNext,
      onPrevious: playPrevious,
    );
  }

  void _setupListeners() {
    _player.stream.position.listen((position) {
      _state.setPosition(position);
    });

    _player.stream.duration.listen((duration) {
      if (duration.inMilliseconds > 0) {
        _state.setDuration(duration);
      }
    });

    _player.stream.playing.listen((playing) {
      if (playing) {
        _state.setPlaybackState(PlaybackState.playing);
      } else {
        if (_state.playbackState == PlaybackState.playing) {
          _state.setPlaybackState(PlaybackState.paused);
        }
      }
    });

    _player.stream.completed.listen((completed) {
      if (completed) {
        _onCompletion();
      }
    });

    _player.stream.buffering.listen((buffering) {
      if (buffering && _state.playbackState != PlaybackState.playing) {
        _state.setPlaybackState(PlaybackState.buffering);
      }
    });
  }

  void _onCompletion() {
    if (_state.isRepeat && _state.currentTrack != null) {
      // 单曲循环不换曲目，封面地址也没变，主动把主题色再套用一次，
      // 避免循环回到同一首时主题色被清掉后不再恢复。
      _syncThemeColor(_state.currentTrack!);
      seek(Duration.zero);
      play();
    } else {
      _state.playNext();
      if (_state.currentTrack != null) {
        playTrack(_state.currentTrack!);
      } else {
        _state.setPlaybackState(PlaybackState.stopped);
      }
    }
  }

  String _getStreamUrl(Track track) {
    if (_repository != null && track.id.isNotEmpty) {
      return _repository!.getStreamUrl(track.id, estimateContentLength: true);
    }
    return track.path;
  }

  String _getCoverArtUrl(Track track) {
    if (track.coverArt.isEmpty) return '';
    if (track.coverArt.startsWith('http')) return track.coverArt;
    if (isLocalCoverPath(track.coverArt)) return track.coverArt;
    if (_repository != null) {
      return _repository!.getCoverArtUrl(track.coverArt, size: 500);
    }
    return track.coverArt;
  }

  Future<void> playTrack(Track track, {String? streamUrl}) async {
    try {
      _state.setError(null);

      final trackWithFullArt = track.copyWith(coverArt: _getCoverArtUrl(track));

      final url = streamUrl ?? _getStreamUrl(trackWithFullArt);

      if (url.isEmpty) {
        throw Exception('No stream URL available');
      }

      await _player.open(mk.Media(url));
      _state.setCurrentTrack(trackWithFullArt);
      // 主题色在这里兜底：封面组件只在图片地址变化时才重新取色，
      // 循环播放同一首时地址不变，必须由播放流程自己补上。
      _syncThemeColor(trackWithFullArt);

      _fetchLyrics(trackWithFullArt);
      audioHandler.setTrack(trackWithFullArt);
    } catch (e) {
      _state.setError('Failed to play track: $e');
      if (kDebugMode) {
        print('Play error: $e');
      }
    }
  }

  Future<void> _fetchLyrics(Track track) async {
    if (track.isLocal) {
      try {
        _state.setLyrics(await loadLocalLyrics(track.path));
      } catch (e) {
        _state.setLyrics(null);
      }
      return;
    }

    if (_repository != null) {
      try {
        final lyrics = await _repository!.getLyricsBySongId(track.id);
        _state.setLyrics(lyrics);
      } catch (e) {
        _state.setLyrics(null);
      }
    }
  }

  Future<void> play() async {
    try {
      await _player.play();
    } catch (e) {
      _state.setError('Failed to play: $e');
    }
  }

  Future<void> pause() async {
    try {
      await _player.pause();
    } catch (e) {
      _state.setError('Failed to pause: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _player.stop();
      _state.setPlaybackState(PlaybackState.stopped);
      _state.setPosition(Duration.zero);
    } catch (e) {
      _state.setError('Failed to stop: $e');
    }
  }

  Future<void> seek(Duration position) async {
    if (_state.currentTrack == null) return;
    try {
      await _player.seek(position);
      _state.setPosition(position);
    } catch (e) {
      _state.setError('Failed to seek: $e');
    }
  }

  Future<void> setVolume(double volume) async {
    try {
      await _player.setVolume(volume.clamp(0.0, 1.0) * 100);
      _state.setVolume(volume.clamp(0.0, 1.0));
    } catch (e) {
      _state.setError('Failed to set volume: $e');
    }
  }

  Future<void> playNext() async {
    _state.playNext();
    if (_state.currentTrack != null) {
      await playTrack(_state.currentTrack!);
    }
  }

  Future<void> playPrevious() async {
    _state.playPrevious();
    if (_state.currentTrack != null) {
      await playTrack(_state.currentTrack!);
    }
  }

  Future<void> playQueue(List<Track> tracks, {int startIndex = 0}) async {
    final tracksWithArt = tracks
        .map((t) => t.copyWith(coverArt: _getCoverArtUrl(t)))
        .toList();
    _state.setQueue(tracksWithArt, startIndex: startIndex);
    if (_state.currentTrack != null) {
      await playTrack(_state.currentTrack!);
    }
  }

  Future<void> addToQueue(Track track) async {
    final trackWithArt = track.copyWith(coverArt: _getCoverArtUrl(track));
    _state.addToQueue(trackWithArt);
  }

  void setShuffle(bool enabled) {
    _state.toggleShuffle();
  }

  void setRepeat(bool enabled) {
    _state.toggleRepeat();
  }

  void updateThemeColor(Color? color) {
    _state.setThemeColor(color);
  }

  /// 让主题色跟随 [track] 的封面。
  ///
  /// 结果按封面地址缓存：命中缓存时同步生效，循环播放回到同一首可以立刻
  /// 继承到上一次的主题色；未命中则异步取色，期间切换到别的曲目会被
  /// [_themeColorRequest] 拦截，取色失败则保持当前主题色不变。
  Future<void> _syncThemeColor(Track track) async {
    final cover = _getCoverArtUrl(track);
    if (cover.isEmpty) return;

    final cached = _coverColorCache[cover];
    if (cached != null) {
      _applyThemeColor(cached);
      return;
    }

    final request = ++_themeColorRequest;
    final color = await _extractThemeColor(cover);
    if (request != _themeColorRequest) return;
    if (color == null) return;
    _coverColorCache[cover] = color;
    _applyThemeColor(color);
  }

  void _applyThemeColor(Color color) {
    if (_state.themeColor != color) {
      _state.setThemeColor(color);
    }
  }

  Future<Color?> _extractThemeColor(String cover) async {
    try {
      final provider = coverColorImageProvider(cover);
      if (provider == null) return null;
      return await extractColorFromCover(provider);
    } catch (e) {
      if (kDebugMode) print('ThemeColor: extract failed: $e');
      return null;
    }
  }

  void updateLyrics(String? lyrics) {
    _state.setLyrics(lyrics);
  }

  Future<void> toggleFavorite(Track track) async {
    if (_repository == null) return;

    try {
      if (_state.isFavorite) {
        await _repository!.unstar(track.id);
        _state.setFavorite(false);
      } else {
        await _repository!.star(track.id);
        _state.setFavorite(true);
      }
    } catch (e) {
      if (kDebugMode) print('Failed to toggle favorite: $e');
    }
  }

  Future<void> scrobble(Track track) async {
    if (_repository == null) return;

    try {
      await _repository!.scrobble(track.id);
    } catch (e) {
      if (kDebugMode) print('Failed to scrobble: $e');
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
