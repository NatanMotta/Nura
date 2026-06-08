import 'dart:async';
import 'package:flutter/foundation.dart';
import 'audio_preview_service.dart';

/// Implementazione di un Mutex Lock per serializzare o scartare 
/// richieste concorrenti dirette al bridge FFI.
class NativeCallMutex {
  Completer<void>? _activeTask;

  /// Esegue la chiusura isolata. Se [dropIfBusy] è true, richieste simultanee
  /// verranno scartate, proteggendo l'engine C++ da spam-tap.
  Future<T> runLocked<T>(Future<T> Function() task, {bool dropIfBusy = false}) async {
    if (_activeTask != null) {
      if (dropIfBusy) {
        throw StateError("Throttle: Operazione nativa scartata per protezione engine.");
      }
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
  String? _preloadedAsset;
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

  /// Pre-memorizza il path del brano successivo.
  void preloadNext(String assetPath) {
    _preloadedAsset = assetPath;
  }

  /// Transizione crossfade blindata contro input spuri.
  Future<void> swipeCrossfadeTransition(String fallbackAssetPath) async {
    _playbackDelayTimer?.cancel();

    final nextAsset = _preloadedAsset ?? fallbackAssetPath;
    _preloadedAsset = null;

    if (nextAsset.isEmpty) return;

    try {
      await _nativeMutex.runLocked(() async {
        await _audio.crossfadeTo(
          trackId: _trackIdFrom(nextAsset),
          assetPath: nextAsset,
        );
      }, dropIfBusy: true);
    } catch (e) {
      debugPrint("🎸 [MusicPlayerManager] Transizione protetta da Mutex: $e");
    }
  }

  void pause() {
    unawaited(_nativeMutex.runLocked(() => _audio.pause()));
  }

  void resume() {
    unawaited(_nativeMutex.runLocked(() => _audio.resume()));
  }

  void dispose() {
    _playbackDelayTimer?.cancel();
    unawaited(_nativeMutex.runLocked(() => _audio.stop()));
  }

  String _trackIdFrom(String assetPath) {
    final name = assetPath.split('/').last;
    return name.replaceAll('.mp3', '').replaceAll('.wav', '');
  }
}
