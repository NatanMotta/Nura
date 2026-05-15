import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:async';

class AudioPreviewService with WidgetsBindingObserver {
  AudioPreviewService._();

  static final AudioPreviewService instance = AudioPreviewService._();

  AudioPlayer? _player;
  final ValueNotifier<String?> playingTrackId = ValueNotifier<String?>(null);
  final ValueNotifier<bool> isPlaying = ValueNotifier(false);
  final ValueNotifier<String?> lastError = ValueNotifier<String?>(null);
  final ValueNotifier<Duration> position = ValueNotifier(Duration.zero);
  final ValueNotifier<Duration?> duration = ValueNotifier(null);
  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  bool _pluginUnavailable = false;
  String? _loadedTrackId;
  bool _wasPlayingBeforeBackground = false;
  bool _lifecycleAttached = false;
  String? get loadedTrackId => _loadedTrackId;
  static const _opTimeout = Duration(seconds: 4);

  AudioPlayer? get _safePlayer {
    if (_pluginUnavailable) return null;
    _attachLifecycleIfNeeded();
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

  void _attachLifecycleIfNeeded() {
    if (_lifecycleAttached) return;
    WidgetsBinding.instance.addObserver(this);
    _lifecycleAttached = true;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final player = _player;
    if (player == null) return;

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused) {
      _wasPlayingBeforeBackground = player.playing;
      if (_wasPlayingBeforeBackground) {
        unawaited(pause());
      }
      return;
    }

    if (state == AppLifecycleState.resumed) {
      if (_wasPlayingBeforeBackground && _loadedTrackId != null) {
        _wasPlayingBeforeBackground = false;
        unawaited(resume());
      }
    }
  }

  Future<void> togglePreview({
    required String trackId,
    required String? assetPath,
  }) async {
    if (assetPath == null || assetPath.isEmpty) {
      _setError('Preview non disponibile per questo brano');
      return;
    }
    final player = _safePlayer;
    if (player == null) {
      _setError('Player audio non disponibile');
      return;
    }

    if (playingTrackId.value == trackId && player.playing) {
      await _runGuarded(() async {
        await player.pause().timeout(_opTimeout);
        isPlaying.value = false;
      });
      return;
    }

    // Same track already loaded and paused: resume from current position.
    if (_loadedTrackId == trackId && !player.playing) {
      playingTrackId.value = trackId;
      await _runGuarded(() async {
        await player.play().timeout(_opTimeout);
        isPlaying.value = true;
      });
      return;
    }

    // Aggiorniamo subito lo stato UI per evitare mismatch con autoplay.
    playingTrackId.value = trackId;
    await _runGuarded(() async {
      await player.stop().timeout(_opTimeout);
      await player.setAsset(assetPath).timeout(_opTimeout);
      _loadedTrackId = trackId;
      await player.play().timeout(_opTimeout);
      isPlaying.value = true;
    });
  }

  Future<void> playTrack({
    required String trackId,
    required String? assetPath,
  }) async {
    if (assetPath == null || assetPath.isEmpty) {
      _setError('Preview non disponibile per questo brano');
      return;
    }
    final player = _safePlayer;
    if (player == null) {
      _setError('Player audio non disponibile');
      return;
    }

    await _runGuarded(() async {
      if (_loadedTrackId != trackId) {
        await player.stop().timeout(_opTimeout);
        await player.setAsset(assetPath).timeout(_opTimeout);
        _loadedTrackId = trackId;
      }
      playingTrackId.value = trackId;
      await player.play().timeout(_opTimeout);
      isPlaying.value = true;
    });
  }

  Future<void> pause() async {
    final player = _safePlayer;
    if (player == null) return;
    await _runGuarded(() async {
      await player.pause().timeout(_opTimeout);
      isPlaying.value = false;
    });
  }

  Future<void> resume() async {
    final player = _safePlayer;
    if (player == null) return;
    if (_loadedTrackId == null) return;
    await _runGuarded(() async {
      await player.play().timeout(_opTimeout);
      isPlaying.value = true;
    });
  }

  Future<void> seek(Duration target) async {
    final player = _safePlayer;
    if (player == null) return;
    await _runGuarded(() async {
      await player.seek(target).timeout(_opTimeout);
    });
  }

  Future<void> stop() async {
    final player = _safePlayer;
    if (player == null) return;
    await player.stop();
    playingTrackId.value = null;
    isPlaying.value = false;
    position.value = Duration.zero;
    _loadedTrackId = null;
    _wasPlayingBeforeBackground = false;
  }

  Future<void> _runGuarded(Future<void> Function() op) async {
    try {
      lastError.value = null;
      await op();
    } on MissingPluginException catch (_) {
      _pluginUnavailable = true;
      playingTrackId.value = null;
      isPlaying.value = false;
      _setError('Plugin audio non disponibile: fai full restart');
      debugPrint(
        'AudioPreviewService: just_audio non disponibile in questa sessione. '
        'Esegui full restart dell\'app.',
      );
    } on TimeoutException catch (_) {
      // Avoid false positives: sometimes the command times out but the player
      // completes asynchronously and keeps working.
      if (_isPlayerOperationalAfterTimeout()) {
        debugPrint(
          'AudioPreviewService: timeout rilevato ma player operativo, '
          'errore utente soppresso.',
        );
        return;
      }
      _setError('Operazione audio in timeout');
    } catch (e) {
      _setError('Errore audio: $e');
    }
  }

  bool _isPlayerOperationalAfterTimeout() {
    final player = _player;
    if (player == null) return false;

    if (player.playing) return true;

    final state = player.playerState.processingState;
    return state == ProcessingState.ready || state == ProcessingState.buffering;
  }

  void _setError(String message) {
    lastError.value = message;
  }
}
