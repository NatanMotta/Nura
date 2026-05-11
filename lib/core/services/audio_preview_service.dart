import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:async';

class AudioPreviewService {
  AudioPreviewService._();

  static final AudioPreviewService instance = AudioPreviewService._();

  AudioPlayer? _player;
  final ValueNotifier<String?> playingTrackId = ValueNotifier<String?>(null);
  final ValueNotifier<bool> isPlaying = ValueNotifier(false);
  final ValueNotifier<Duration> position = ValueNotifier(Duration.zero);
  final ValueNotifier<Duration?> duration = ValueNotifier(null);
  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  bool _pluginUnavailable = false;
  String? _loadedTrackId;
  String? get loadedTrackId => _loadedTrackId;

  AudioPlayer? get _safePlayer {
    if (_pluginUnavailable) return null;
    _player ??= AudioPlayer()..setLoopMode(LoopMode.one);
    _positionSub ??= _player!.positionStream.listen((value) {
      position.value = value;
    });
    _durationSub ??= _player!.durationStream.listen((value) {
      duration.value = value;
    });
    _playerStateSub ??= _player!.playerStateStream.listen((state) {
      isPlaying.value = state.playing;
    });
    return _player;
  }

  Future<void> togglePreview({
    required String trackId,
    required String? assetPath,
  }) async {
    if (assetPath == null || assetPath.isEmpty) return;
    final player = _safePlayer;
    if (player == null) return;

    if (playingTrackId.value == trackId && player.playing) {
      await player.pause();
      isPlaying.value = false;
      return;
    }

    // Same track already loaded and paused: resume from current position.
    if (_loadedTrackId == trackId && !player.playing) {
      playingTrackId.value = trackId;
      await player.play();
      isPlaying.value = true;
      return;
    }

    try {
      // Aggiorniamo subito lo stato UI per evitare mismatch con autoplay.
      playingTrackId.value = trackId;
      await player.stop();
      await player.setAsset(assetPath);
      _loadedTrackId = trackId;
      await player.play();
      isPlaying.value = true;
    } on MissingPluginException catch (_) {
      _pluginUnavailable = true;
      playingTrackId.value = null;
      isPlaying.value = false;
      debugPrint(
        'AudioPreviewService: just_audio non disponibile in questa sessione. '
        'Esegui full restart dell\'app.',
      );
    }
  }

  Future<void> playTrack({
    required String trackId,
    required String? assetPath,
  }) async {
    if (assetPath == null || assetPath.isEmpty) return;
    final player = _safePlayer;
    if (player == null) return;

    try {
      if (_loadedTrackId != trackId) {
        await player.stop();
        await player.setAsset(assetPath);
        _loadedTrackId = trackId;
      }
      playingTrackId.value = trackId;
      await player.play();
      isPlaying.value = true;
    } on MissingPluginException catch (_) {
      _pluginUnavailable = true;
      playingTrackId.value = null;
      isPlaying.value = false;
    }
  }

  Future<void> pause() async {
    final player = _safePlayer;
    if (player == null) return;
    await player.pause();
    isPlaying.value = false;
  }

  Future<void> resume() async {
    final player = _safePlayer;
    if (player == null) return;
    if (_loadedTrackId == null) return;
    await player.play();
    isPlaying.value = true;
  }

  Future<void> seek(Duration target) async {
    final player = _safePlayer;
    if (player == null) return;
    await player.seek(target);
  }

  Future<void> stop() async {
    final player = _safePlayer;
    if (player == null) return;
    await player.stop();
    playingTrackId.value = null;
    isPlaying.value = false;
    position.value = Duration.zero;
    _loadedTrackId = null;
  }
}
