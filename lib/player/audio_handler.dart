import 'dart:async';
import 'dart:io';
import 'package:audio_service/audio_service.dart' as audio;
import 'package:dio/dio.dart';
import 'package:media_kit/media_kit.dart' as mk;
import 'package:path_provider/path_provider.dart';
import 'player_state.dart';
import '../models/models.dart';
import '../api/repository.dart';
import '../api/cover_art.dart';

class MusicAudioHandler extends audio.BaseAudioHandler {
  mk.Player? _player;
  PlayerState? _state;
  MusicRepository? _repository;
  void Function()? _onNext;
  void Function()? _onPrevious;
  final List<StreamSubscription> _subscriptions = [];
  Timer? _syncTimer;

  void bind(
    mk.Player player,
    PlayerState state,
    MusicRepository? repository, {
    void Function()? onNext,
    void Function()? onPrevious,
  }) {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
    _syncTimer?.cancel();

    _player = player;
    _state = state;
    _repository = repository;
    _onNext = onNext;
    _onPrevious = onPrevious;

    _subscriptions.add(_player!.stream.playing.listen((_) => _throttledSync()));
    _subscriptions.add(_player!.stream.position.listen((_) => _throttledSync()));
    _subscriptions.add(_player!.stream.duration.listen((_) => _throttledSync()));
    _subscriptions.add(_player!.stream.buffering.listen((_) => _throttledSync()));
  }

  void _throttledSync() {
    if (_syncTimer == null || !_syncTimer!.isActive) {
      _syncState();
      _syncTimer = Timer(const Duration(milliseconds: 200), () {});
    }
  }

  Future<void> setTrack(Track track) async {
    final String coverRef;
    if (track.coverArt.isEmpty) {
      coverRef = '';
    } else if (track.coverArt.startsWith('http') ||
        isLocalCoverPath(track.coverArt)) {
      coverRef = track.coverArt;
    } else {
      coverRef = _repository?.getCoverArtUrl(track.coverArt, size: 500) ?? '';
    }

    Uri? artUri;
    if (coverRef.isNotEmpty) {
      artUri = isLocalCoverPath(coverRef)
          ? _localArtUri(coverRef)
          : await _downloadArt(track.id, coverRef);
    }

    mediaItem.add(audio.MediaItem(
      id: track.id,
      title: track.title,
      artist: track.artist,
      album: track.album,
      duration: Duration(seconds: track.duration),
      artUri: artUri,
    ));
    _syncState();
  }

  Future<Uri?> _downloadArt(String trackId, String url) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/audio_art_$trackId.jpg');
      if (!await file.exists()) {
        final resp = await Dio().get<List<int>>(
          url,
          options: Options(responseType: ResponseType.bytes),
        );
        await file.writeAsBytes(resp.data!);
      }
      return Uri.file(file.path);
    } catch (e) {
      return Uri.parse(url);
    }
  }

  /// Points the media session at a cover file already on this device.
  Uri? _localArtUri(String path) {
    try {
      final file = path.startsWith('file://')
          ? File.fromUri(Uri.parse(path))
          : File(path);
      return file.existsSync() ? Uri.file(file.path) : null;
    } catch (e) {
      return null;
    }
  }

  void _syncState() {
    if (_player == null) return;
    final playing = _player!.state.playing;
    final position = _player!.state.position;
    playbackState.add(audio.PlaybackState(
      playing: playing,
      updatePosition: position,
      bufferedPosition: Duration.zero,
      speed: 1.0,
      processingState: _player!.state.buffering
          ? audio.AudioProcessingState.buffering
          : audio.AudioProcessingState.ready,
      controls: [
        audio.MediaControl.skipToPrevious,
        if (playing) audio.MediaControl.pause else audio.MediaControl.play,
        audio.MediaControl.stop,
        audio.MediaControl.skipToNext,
      ],
      systemActions: const {
        audio.MediaAction.seek,
        audio.MediaAction.seekForward,
        audio.MediaAction.seekBackward,
      },
    ));
  }

  @override
  Future<void> play() async => _player?.play();

  @override
  Future<void> pause() async => _player?.pause();

  @override
  Future<void> stop() async {
    await _player?.pause();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) async => _player?.seek(position);

  @override
  Future<void> skipToNext() async => _onNext?.call();

  @override
  Future<void> skipToPrevious() async => _onPrevious?.call();
}
