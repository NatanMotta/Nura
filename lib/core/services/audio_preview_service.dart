import 'package:flutter/widgets.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'dart:async';

/// Motore audio globale C++ FFI (SoLoud) con gestione delegata (autoDispose).
class AudioPreviewService with WidgetsBindingObserver {
  AudioPreviewService._();
  static final AudioPreviewService instance = AudioPreviewService._();

  final ValueNotifier<String?> playingTrackId = ValueNotifier<String?>(null);
  final ValueNotifier<bool> isPlaying = ValueNotifier(false);
  final ValueNotifier<String?> lastError = ValueNotifier<String?>(null);
  final ValueNotifier<Duration> position = ValueNotifier(Duration.zero);
  final ValueNotifier<Duration?> duration = ValueNotifier(null);

  bool _isInit = false;
  Completer<void>? _nativeInitCompleter;
  bool _lifecycleAttached = false;
  bool _wasPlayingBeforeBackground = false;
  String? _loadedTrackId;
  String? get loadedTrackId => _loadedTrackId;

  SoundHandle? _currentHandle;

  /// RequestID monotono crescente per annullare caricamenti asincroni obsoleti.
  int _loadRequestId = 0;

  Timer? _positionTimer;

  Future<void> _ensureInit() async {
    if (_isInit) return;

    if (_nativeInitCompleter != null) {
      await _nativeInitCompleter!.future;
      return;
    }

    _nativeInitCompleter = Completer<void>();

    try {
      if (!SoLoud.instance.isInitialized) {
        debugPrint('AudioPreviewService: Initializing SoLoud...');
        await SoLoud.instance.init();
        debugPrint('AudioPreviewService: SoLoud Initialized successfully.');
      } else {
        debugPrint('AudioPreviewService: SoLoud was already initialized.');
      }
      _isInit = true;
      _attachLifecycleIfNeeded();

      _nativeInitCompleter!.complete();
    } catch (e, stackTrace) {
      _nativeInitCompleter!.completeError(e, stackTrace);
      _setError('SoLoud Init Error: $e');
    } finally {
      _nativeInitCompleter = null;
    }
  }

  void _attachLifecycleIfNeeded() {
    if (_lifecycleAttached) return;
    WidgetsBinding.instance.addObserver(this);
    _lifecycleAttached = true;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused) {
      _wasPlayingBeforeBackground = isPlaying.value;
      if (_wasPlayingBeforeBackground) {
        unawaited(safePause());
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_wasPlayingBeforeBackground && _loadedTrackId != null) {
        _wasPlayingBeforeBackground = false;
        unawaited(resume());
      }
    }
  }

  void _startPositionTimer() {
    _positionTimer?.cancel();
    _positionTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (_currentHandle != null && isPlaying.value && _isInit) {
        if (SoLoud.instance.getIsValidVoiceHandle(_currentHandle!)) {
          try {
            final pos = SoLoud.instance.getPosition(_currentHandle!);
            position.value = pos;
          } catch (_) {}
        } else {
          _currentHandle = null;
          isPlaying.value = false;
          _stopPositionTimer();
        }
      }
    });
  }

  void _stopPositionTimer() {
    _positionTimer?.cancel();
    _positionTimer = null;
  }

  Future<void> togglePreview(
      {required String trackId, required String? assetPath}) async {
    if (assetPath == null || assetPath.isEmpty) {
      _setError('Preview non disponibile per questo brano');
      return;
    }
    await _ensureInit();

    if (playingTrackId.value == trackId && isPlaying.value) {
      await safePause();
      return;
    }

    if (_loadedTrackId == trackId && !isPlaying.value) {
      await resume();
      return;
    }

    await playTrack(trackId: trackId, assetPath: assetPath);
  }

  /// Riproduce un brano garantendo assenza di leak nativi e di SIGSEGV.
  Future<bool> playTrack({required String trackId, required String? assetPath}) async {
    if (assetPath == null || assetPath.isEmpty) {
      _setError('Preview non disponibile per questo brano');
      return false;
    }
    await _ensureInit();
    lastError.value = null;

    final thisRequestId = ++_loadRequestId;

    try {
      // Validazione di sicurezza prima di intercettare il thread nativo
      if (_currentHandle != null && SoLoud.instance.getIsValidVoiceHandle(_currentHandle!)) {
        await SoLoud.instance.stop(_currentHandle!);
      }
      _currentHandle = null;

      // Caricamento asincrono con delega assoluta della memoria
      final AudioSource temporarySource = await SoLoud.instance.loadAsset(
        assetPath,
        mode: LoadMode.memory,
        autoDispose: true,
      );

      if (thisRequestId != _loadRequestId) {
        // Obsoleto, la risorsa andrebbe scartata ma autoDispose ci pensa se lanciamo play e poi stop,
        // però non è partita. Dobbiamo disporla manualmente se non partiamo.
        // flutter_soloud disposeSource è sicuro da chiamare finché l'handle non prende possesso
        SoLoud.instance.disposeSource(temporarySource);
        return false;
      }

      _loadedTrackId = trackId;
      duration.value = SoLoud.instance.getLength(temporarySource);

      playingTrackId.value = trackId;
      _currentHandle = SoLoud.instance.play(temporarySource, looping: true);
      isPlaying.value = true;
      _startPositionTimer();
      return true;
    } catch (e, stackTrace) {
      debugPrint('🚨 FFI Execution Error: $e\n$stackTrace');
      if (thisRequestId == _loadRequestId) {
        _setError('Errore audio: $e');
      }
      return false;
    }
  }

  /// Crossfade rapido: sfuma la traccia attuale in C++ e avvia subito la nuova.
  Future<void> crossfadeTo(
      {required String trackId, required String? assetPath}) async {
    if (assetPath == null || assetPath.isEmpty) return;
    await _ensureInit();

    final oldHandle = _currentHandle;

    if (oldHandle != null && SoLoud.instance.getIsValidVoiceHandle(oldHandle)) {
      SoLoud.instance.fadeVolume(oldHandle, 0.0, const Duration(milliseconds: 100));
      SoLoud.instance.scheduleStop(oldHandle, const Duration(milliseconds: 100));
      _currentHandle = null;
      _loadedTrackId = null;
    }

    await playTrack(trackId: trackId, assetPath: assetPath);
  }

  /// Sospende l'audio in modo thread-safe.
  Future<void> safePause() async {
    if (_currentHandle == null) return;
    
    if (_isInit && SoLoud.instance.getIsValidVoiceHandle(_currentHandle!)) {
      SoLoud.instance.setPause(_currentHandle!, true);
      isPlaying.value = false;
      _stopPositionTimer();
    } else {
      _currentHandle = null;
      isPlaying.value = false;
      _stopPositionTimer();
    }
  }

  Future<void> pause() async => safePause();

  Future<void> resume() async {
    if (_currentHandle != null && _isInit && SoLoud.instance.getIsValidVoiceHandle(_currentHandle!)) {
      SoLoud.instance.setPause(_currentHandle!, false);
      isPlaying.value = true;
      _startPositionTimer();
    } else {
      _currentHandle = null;
      isPlaying.value = false;
    }
  }

  Future<void> seek(Duration target) async {
    if (_currentHandle != null && _isInit && SoLoud.instance.getIsValidVoiceHandle(_currentHandle!)) {
      SoLoud.instance.seek(_currentHandle!, target);
      position.value = target;
    }
  }

  Future<void> stop() async {
    if (_currentHandle != null && _isInit && SoLoud.instance.getIsValidVoiceHandle(_currentHandle!)) {
      try {
        SoLoud.instance.stop(_currentHandle!);
      } catch (_) {}
    }
    _currentHandle = null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      playingTrackId.value = null;
      isPlaying.value = false;
      position.value = Duration.zero;
    });

    _loadedTrackId = null;
    _wasPlayingBeforeBackground = false;
    _stopPositionTimer();
  }

  /// Smantellamento totale.
  void disposeAll() {
    _stopPositionTimer();
    if (_currentHandle != null && _isInit && SoLoud.instance.getIsValidVoiceHandle(_currentHandle!)) {
      try {
        SoLoud.instance.stop(_currentHandle!);
      } catch (_) {}
    }
    _currentHandle = null;
    _loadedTrackId = null;
    playingTrackId.value = null;
    isPlaying.value = false;
    position.value = Duration.zero;
    _wasPlayingBeforeBackground = false;
    
    if (_isInit) {
      try {
        SoLoud.instance.deinit();
      } catch (_) {}
      _isInit = false;
    }
  }

  void _setError(String message) {
    lastError.value = message;
    debugPrint(message);
  }
}
