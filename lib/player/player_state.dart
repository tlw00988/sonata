import 'package:flutter/material.dart';
import '../models/models.dart';

enum PlaybackState { stopped, playing, paused, buffering, error }

class PlayerState extends ChangeNotifier {
  Track? _currentTrack;
  List<Track> _queue = [];
  int _currentIndex = -1;
  PlaybackState _playbackState = PlaybackState.stopped;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _volume = 1.0;
  bool _isShuffle = false;
  bool _isRepeat = false;
  Color? _themeColor;
  String? _lyrics;
  String? _error;
  bool _isFavorite = false;

  Track? get currentTrack => _currentTrack;
  List<Track> get queue => List.unmodifiable(_queue);
  int get currentIndex => _currentIndex;
  PlaybackState get playbackState => _playbackState;
  Duration get position => _position;
  Duration get duration => _duration;
  double get volume => _volume;
  bool get isShuffle => _isShuffle;
  bool get isRepeat => _isRepeat;
  Color? get themeColor => _themeColor;
  String? get lyrics => _lyrics;
  String? get error => _error;
  bool get isFavorite => _isFavorite;

  bool get isPlaying => _playbackState == PlaybackState.playing;
  bool get isPaused => _playbackState == PlaybackState.paused;
  bool get hasQueue => _queue.isNotEmpty;
  bool get hasCurrentTrack => _currentTrack != null;
  double get progress => _duration.inMilliseconds > 0
      ? _position.inMilliseconds / _duration.inMilliseconds
      : 0.0;

  String get formattedPosition => _formatDuration(_position);
  String get formattedDuration => _formatDuration(_duration);

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void setCurrentTrack(Track track, {int? index}) {
    _currentTrack = track;
    _isFavorite = false;
    if (index != null) {
      _currentIndex = index;
    }
    _position = Duration.zero;
    _duration = Duration(seconds: track.duration);
    _error = null;
    notifyListeners();
  }

  void setQueue(List<Track> tracks, {int startIndex = 0}) {
    _queue = List.from(tracks);
    _currentIndex = startIndex.clamp(0, _queue.length - 1);
    if (_queue.isNotEmpty) {
      setCurrentTrack(_queue[_currentIndex], index: _currentIndex);
    }
    notifyListeners();
  }

  void addToQueue(Track track) {
    _queue.add(track);
    notifyListeners();
  }

  void removeFromQueue(int index) {
    if (index >= 0 && index < _queue.length) {
      _queue.removeAt(index);
      if (index <= _currentIndex && _currentIndex > 0) {
        _currentIndex--;
      }
      notifyListeners();
    }
  }

  void clearQueue() {
    _queue.clear();
    _currentIndex = -1;
    _currentTrack = null;
    _position = Duration.zero;
    _duration = Duration.zero;
    notifyListeners();
  }

  void moveQueueItem(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _queue.length) return;
    if (newIndex < 0 || newIndex >= _queue.length) return;

    final item = _queue.removeAt(oldIndex);
    _queue.insert(newIndex, item);

    if (oldIndex == _currentIndex) {
      _currentIndex = newIndex;
    } else if (oldIndex < _currentIndex && newIndex >= _currentIndex) {
      _currentIndex--;
    } else if (oldIndex > _currentIndex && newIndex <= _currentIndex) {
      _currentIndex++;
    }
    notifyListeners();
  }

  void setPlaybackState(PlaybackState state) {
    _playbackState = state;
    if (state == PlaybackState.stopped) {
      _error = null;
      _themeColor = null;
    } else if (state == PlaybackState.error) {
      _error = 'Playback error';
    } else {
      _error = null;
    }
    notifyListeners();
  }

  void setPosition(Duration position) {
    _position = position;
    notifyListeners();
  }

  void setDuration(Duration duration) {
    _duration = duration;
    notifyListeners();
  }

  void setVolume(double volume) {
    _volume = volume.clamp(0.0, 1.0);
    notifyListeners();
  }

  void toggleShuffle() {
    _isShuffle = !_isShuffle;
    notifyListeners();
  }

  void toggleRepeat() {
    _isRepeat = !_isRepeat;
    notifyListeners();
  }

  void setThemeColor(Color? color) {
    if (_themeColor == color) return;
    _themeColor = color;
    notifyListeners();
  }

  void setLyrics(String? lyrics) {
    _lyrics = lyrics;
    notifyListeners();
  }

  void setError(String? error) {
    _error = error;
    _playbackState = PlaybackState.error;
    notifyListeners();
  }

  void setFavorite(bool favorite) {
    _isFavorite = favorite;
    notifyListeners();
  }

  void toggleFavorite() {
    _isFavorite = !_isFavorite;
    notifyListeners();
  }

  Track? getNextTrack() {
    if (_queue.isEmpty) return null;
    if (_isShuffle) {
      final random = DateTime.now().millisecondsSinceEpoch % _queue.length;
      return _queue[random];
    }
    final nextIndex = _currentIndex + 1;
    if (nextIndex < _queue.length) {
      return _queue[nextIndex];
    }
    if (_isRepeat && _queue.isNotEmpty) {
      return _queue[0];
    }
    return null;
  }

  Track? getPreviousTrack() {
    if (_queue.isEmpty) return null;
    final prevIndex = _currentIndex - 1;
    if (prevIndex >= 0) {
      return _queue[prevIndex];
    }
    if (_isRepeat && _queue.isNotEmpty) {
      return _queue[_queue.length - 1];
    }
    return null;
  }

  void playNext() {
    final next = getNextTrack();
    if (next != null) {
      final nextIndex = _queue.indexOf(next);
      setCurrentTrack(next, index: nextIndex);
    }
  }

  void playPrevious() {
    final prev = getPreviousTrack();
    if (prev != null) {
      final prevIndex = _queue.indexOf(prev);
      setCurrentTrack(prev, index: prevIndex);
    }
  }
}
