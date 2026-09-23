import 'dart:async';
import 'dart:ui' show Color;
import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart' as mk;
import 'player_state.dart';
import 'audio_handler.dart';
import '../models/models.dart';
import '../api/api.dart';
import '../main.dart' show audioHandler;

class PlayerController extends ChangeNotifier {
  late final mk.Player _player;
  final PlayerState _state;
  
  MusicRepository? _repository;

  PlayerState get state => _state;

  PlayerController({PlayerState? state}) : _state = state ?? PlayerState() {
    mk.MediaKit.ensureInitialized();
    _player = mk.Player();
    _setupListeners();
    audioHandler.bind(_player, _state, _repository,
        onNext: playNext, onPrevious: playPrevious);
  }

  void setRepository(MusicRepository repository) {
    _repository = repository;
    audioHandler.bind(_player, _state, _repository,
        onNext: playNext, onPrevious: playPrevious);
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
      
      final trackWithFullArt = track.copyWith(
        coverArt: _getCoverArtUrl(track),
      );
      
      final url = streamUrl ?? _getStreamUrl(trackWithFullArt);
      
      if (url.isEmpty) {
        throw Exception('No stream URL available');
      }

      await _player.open(mk.Media(url));
      _state.setCurrentTrack(trackWithFullArt);
      
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
    final tracksWithArt = tracks.map((t) => t.copyWith(coverArt: _getCoverArtUrl(t))).toList();
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
