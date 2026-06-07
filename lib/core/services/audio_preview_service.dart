import 'package:flutter/widgets.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'dart:async';

/// Motore audio globale C++ FFI (SoLoud) con gestione sicura della memoria nativa.
///
/// Ogni AudioSource allocata nell'heap C++ viene tracciata e deallocata
/// esplicitamente. Il mutex di inizializzazione impedisce deadlock da
/// chiamate concorrenti a init(). Il sistema di RequestID annulla le
/// operazioni asincrone obsolete durante swipe rapidi.
class AudioPreviewService with WidgetsBindingObserver {
  AudioPreviewService._();
  static final AudioPreviewService instance = AudioPreviewService._();

  final ValueNotifier<String?> playingTrackId = ValueNotifier<String?>(null);
  final ValueNotifier<bool> isPlaying = ValueNotifier(false);
  final ValueNotifier<String?> lastError = ValueNotifier<String?>(null);
  final ValueNotifier<Duration> position = ValueNotifier(Duration.zero);
  final ValueNotifier<Duration?> duration = ValueNotifier(null);

  bool _isInit = false;
  bool _isInitializing = false; // Mutex: impedisce init() concorrenti
  bool _lifecycleAttached = false;
  bool _wasPlayingBeforeBackground = false;
  String? _loadedTrackId;
  String? get loadedTrackId => _loadedTrackId;

  SoundHandle? _currentHandle;
  AudioSource? _currentSource;

  /// Traccia tutte le AudioSource allocate nell'heap C++ per deallocazione esplicita.
  final Map<String, AudioSource> _allocatedSources = {};

  /// RequestID monotono crescente per annullare caricamenti asincroni obsoleti.
  int _loadRequestId = 0;

  Timer? _positionTimer;

  /// Inizializzazione thread-safe con mutex logico.
  /// Se due widget chiamano _ensureInit() nello stesso frame, solo il primo
  /// esegue SoLoud.instance.init(). Il secondo attende il completamento.
  Future<void> _ensureInit() async {
    if (_isInit) return;
    if (_isInitializing) {
      while (_isInitializing && !_isInit) {
        await Future.delayed(const Duration(milliseconds: 10));
      }
      return;
    }
    _isInitializing = true;
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
    } catch (e) {
      _setError('SoLoud Init Error: $e');
    } finally {
      _isInitializing = false;
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
        unawaited(pause());
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
        try {
          final pos = SoLoud.instance.getPosition(_currentHandle!);
          position.value = pos;
        } catch (_) {}
      }
    });
  }

  void _stopPositionTimer() {
    _positionTimer?.cancel();
    _positionTimer = null;
  }

  Future<void> togglePreview({required String trackId, required String? assetPath}) async {
    if (assetPath == null || assetPath.isEmpty) {
      _setError('Preview non disponibile per questo brano');
      return;
    }
    await _ensureInit();

    if (playingTrackId.value == trackId && isPlaying.value) {
      await pause();
      return;
    }

    if (_loadedTrackId == trackId && !isPlaying.value) {
      await resume();
      return;
    }

    await playTrack(trackId: trackId, assetPath: assetPath);
  }

  Future<void> playTrack({required String trackId, required String? assetPath}) async {
    if (assetPath == null || assetPath.isEmpty) {
      _setError('Preview non disponibile per questo brano');
      return;
    }
    await _ensureInit();
    lastError.value = null;

    // Genera un ID univoco per questa richiesta di caricamento.
    // Se arriva una nuova richiesta prima che questa finisca, l'ID cambia
    // e il risultato di questa viene scartato (annullamento implicito).
    final thisRequestId = ++_loadRequestId;

    try {
      if (_loadedTrackId != trackId) {
        // Stop l'handle corrente prima di cambiare sorgente
        if (_currentHandle != null) {
          try { SoLoud.instance.stop(_currentHandle!); } catch (_) {}
          _currentHandle = null;
        }

        // Caricamento asincrono: qui il controllo torna all'event loop.
        // Se l'utente fa un altro swipe, _loadRequestId cambia.
        final newSource = await SoLoud.instance.loadAsset(assetPath);

        // === ANNULLAMENTO IMPLICITO ===
        // Se durante il caricamento è arrivata un'altra richiesta, questa
        // è obsoleta. Dealloca immediatamente la sorgente appena caricata.
        if (thisRequestId != _loadRequestId) {
          SoLoud.instance.disposeSource(newSource);
          return;
        }

        // Dealloca la sorgente precedente dall'heap C++
        _disposeCurrentSource();

        _currentSource = newSource;
        _loadedTrackId = trackId;
        _allocatedSources[trackId] = newSource;
        duration.value = SoLoud.instance.getLength(newSource);
      }

      // Secondo controllo: la richiesta è ancora valida?
      if (thisRequestId != _loadRequestId) return;

      playingTrackId.value = trackId;
      _currentHandle = SoLoud.instance.play(_currentSource!, looping: true);
      isPlaying.value = true;
      _startPositionTimer();
    } catch (e) {
      if (thisRequestId == _loadRequestId) {
        _setError('Errore audio: $e');
      }
    }
  }

  /// Crossfade rapido: sfuma la traccia attuale in C++ e avvia subito la nuova.
  /// La vecchia AudioSource viene deallocata dall'heap C++ dopo il fade.
  Future<void> crossfadeTo({required String trackId, required String? assetPath}) async {
    if (assetPath == null || assetPath.isEmpty) return;
    await _ensureInit();

    final oldHandle = _currentHandle;
    final oldSource = _currentSource;
    final oldTrackId = _loadedTrackId;

    if (oldHandle != null && oldSource != null) {
      // Sfuma il volume normalmente tramite DSP.
      SoLoud.instance.fadeVolume(oldHandle, 0.0, const Duration(milliseconds: 100));
      SoLoud.instance.scheduleStop(oldHandle, const Duration(milliseconds: 100));
      
      // PATCH: Timeout di fallback per lo stream FFI nativo per evitare
      // memory leak in caso di drop nativo dell'evento (Bug SoLoud #324).
      unawaited(Future.any([
        oldSource.allInstancesFinished.first,
        Future.delayed(const Duration(milliseconds: 500))
      ]).then((_) {
        try {
          if (_isInit) {
            SoLoud.instance.disposeSource(oldSource);
            if (oldTrackId != null) _allocatedSources.remove(oldTrackId);
          }
        } catch (_) {}
      }));
      _currentHandle = null;
      _currentSource = null;
      _loadedTrackId = null;
    }

    await playTrack(trackId: trackId, assetPath: assetPath);
  }

  /// Dealloca la sorgente corrente dall'heap C++.
  void _disposeCurrentSource() {
    if (_currentSource != null && _isInit) {
      try {
        SoLoud.instance.disposeSource(_currentSource!);
      } catch (_) {}
      if (_loadedTrackId != null) _allocatedSources.remove(_loadedTrackId);
      _currentSource = null;
    }
  }

  /// Dealloca una sorgente specifica dal trackId (invocato dal MusicPlayerManager).
  void disposeSourceByTrackId(String trackId) {
    final source = _allocatedSources.remove(trackId);
    if (source != null && _isInit) {
      try {
        SoLoud.instance.disposeSource(source);
      } catch (_) {}
    }
  }

  Future<void> pause() async {
    if (_currentHandle != null && _isInit) {
      SoLoud.instance.setPause(_currentHandle!, true);
      isPlaying.value = false;
      _stopPositionTimer();
    }
  }

  Future<void> resume() async {
    if (_currentHandle != null && _isInit) {
      SoLoud.instance.setPause(_currentHandle!, false);
      isPlaying.value = true;
      _startPositionTimer();
    }
  }

  Future<void> seek(Duration target) async {
    if (_currentHandle != null && _isInit) {
      SoLoud.instance.seek(_currentHandle!, target);
      position.value = target;
    }
  }

  Future<void> stop() async {
    if (_currentHandle != null && _isInit) {
      try { SoLoud.instance.stop(_currentHandle!); } catch (_) {}
      _currentHandle = null;
    }
    // DEALLOCAZIONE ESPLICITA al stop globale
    _disposeCurrentSource();
    
    // Esegui gli update di stato nel prossimo frame per evitare eccezioni
    // "widget tree locked" durante lo smontaggio sincrono (es. PopScope)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      playingTrackId.value = null;
      isPlaying.value = false;
      position.value = Duration.zero;
    });
    
    _loadedTrackId = null;
    _wasPlayingBeforeBackground = false;
    _stopPositionTimer();
  }

  /// Smantellamento totale: dealloca TUTTE le sorgenti dall'heap C++.
  /// Invocato quando l'app viene chiusa o il widget principale viene smontato.
  void disposeAll() {
    _stopPositionTimer();
    if (_currentHandle != null && _isInit) {
      try { SoLoud.instance.stop(_currentHandle!); } catch (_) {}
      _currentHandle = null;
    }
    // Distrugge ogni singola AudioSource tracciata
    for (final source in _allocatedSources.values) {
      try {
        if (_isInit) SoLoud.instance.disposeSource(source);
      } catch (_) {}
    }
    _allocatedSources.clear();
    _currentSource = null;
    _loadedTrackId = null;
    playingTrackId.value = null;
    isPlaying.value = false;
    position.value = Duration.zero;
    _wasPlayingBeforeBackground = false;
    // Deinizializza il motore C++
    if (_isInit) {
      try { SoLoud.instance.deinit(); } catch (_) {}
      _isInit = false;
    }
  }

  void _setError(String message) {
    lastError.value = message;
    debugPrint(message);
  }
}
