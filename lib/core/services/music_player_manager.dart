import 'dart:async';
import 'package:flutter/foundation.dart';
import 'audio_preview_service.dart';

/// Implementazione di un Mutex Lock per serializzare o scartare 
/// richieste concorrenti dirette al bridge FFI.
class NativeCallMutex {
  Completer<void>? _activeTask;

  /// Serializza le richieste native, anche con più chiamanti in attesa.
  Future<T> runLocked<T>(Future<T> Function() task) async {
    while (_activeTask != null) {
      await _activeTask!.future;
    }
    
    _activeTask = Completer<void>();
    try {
      return await task();
    } finally {
      _activeTask!.complete();
      _activeTask = null;
    }
  }
}

/// Gestore audio per la sezione Discovery/Swipe.
class MusicPlayerManager {
  int _transitionId = 0;
  Timer? _playbackDelayTimer;

  final _audio = AudioPreviewService.instance;
  final NativeCallMutex _nativeMutex = NativeCallMutex();

  /// Avvia la riproduzione della prima traccia nel deck.
  Future<void> initFirstTrack(String assetPath) async {
    if (assetPath.isEmpty) return;
    
    try {
      final executionSuccess = await _nativeMutex.runLocked(() async {
        return await _audio.playTrack(
          trackId: _trackIdFrom(assetPath),
          assetPath: assetPath,
        );
      });
      
      if (!executionSuccess) {
         _gracefulAudioFailureFallback("Inizializzazione nativa fallita o file non supportato.");
      }
    } on Exception catch (e, stacktrace) {
      debugPrint("🎸 [MusicPlayerManager] Non-Fatal FFI Failure: $e\n$stacktrace");
      _gracefulAudioFailureFallback("Servizio audio temporaneamente indisponibile.");
    } catch (e) {
      debugPrint("🎸 [MusicPlayerManager] Error: $e");
      _gracefulAudioFailureFallback("Servizio audio temporaneamente indisponibile.");
    }
  }

  void _gracefulAudioFailureFallback(String reason) {
     _audio.playingTrackId.value = null;
     debugPrint("Audio fallback: $reason");
  }

  /// Transizione crossfade blindata contro input spuri.
  Future<void> swipeCrossfadeTransition(String fallbackAssetPath) async {
    _playbackDelayTimer?.cancel();

    final nextAsset = fallbackAssetPath;
    final transitionId = ++_transitionId;

    if (nextAsset.isEmpty) return;

    try {
      await _nativeMutex.runLocked(() async {
        if (transitionId != _transitionId) return;
        await _audio.crossfadeTo(
          trackId: _trackIdFrom(nextAsset),
          assetPath: nextAsset,
        );
      });
    } catch (e) {
      debugPrint("[MusicPlayerManager] Errore transizione audio: $e");
    }
  }

  void pause() {
    _transitionId++;
    unawaited(_nativeMutex.runLocked(() => _audio.pause()));
  }

  void resume() {
    unawaited(_nativeMutex.runLocked(() => _audio.resume()));
  }

  void dispose() {
    _transitionId++;
    _playbackDelayTimer?.cancel();
    unawaited(_nativeMutex.runLocked(() => _audio.stop()));
  }

  String _trackIdFrom(String assetPath) {
    final name = assetPath.split('/').last;
    return name.replaceAll('.mp3', '').replaceAll('.wav', '');
  }
}
