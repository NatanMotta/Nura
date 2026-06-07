import 'dart:async';
import 'package:flutter/foundation.dart';
import 'audio_preview_service.dart';

/// Gestore audio per la sezione Discovery/Swipe.
/// Delegata tutto il playback ad AudioPreviewService (singleton C++ FFI SoLoud).
/// Gestisce il ciclo di vita delle sorgenti C++ per prevenire memory leak.
class MusicPlayerManager {
  String? _preloadedAsset;
  Timer? _playbackDelayTimer;

  final _audio = AudioPreviewService.instance;

  /// Avvia la riproduzione della prima traccia nel deck.
  Future<void> initFirstTrack(String assetPath) async {
    if (assetPath.isEmpty) return;
    try {
      await _audio.playTrack(
        trackId: _trackIdFrom(assetPath),
        assetPath: assetPath,
      );
    } catch (e) {
      debugPrint("MusicPlayerManager Error: $e");
    }
  }

  /// Pre-memorizza il path del brano successivo per transizione istantanea.
  void preloadNext(String assetPath) {
    _preloadedAsset = assetPath;
  }

  /// Crossfade rapido: sfuma la traccia attuale in C++ e avvia subito la prossima.
  /// La vecchia AudioSource viene deallocata dall'heap C++ internamente
  /// da crossfadeTo() in AudioPreviewService.
  void swipeCrossfadeTransition(String fallbackAssetPath) {
    _playbackDelayTimer?.cancel();

    final nextAsset = _preloadedAsset ?? fallbackAssetPath;
    _preloadedAsset = null;

    if (nextAsset.isEmpty) return;

    try {
      unawaited(_audio.crossfadeTo(
        trackId: _trackIdFrom(nextAsset),
        assetPath: nextAsset,
      ));
    } catch (e) {
      debugPrint("Playback Error: $e");
    }
  }

  void pause() {
    unawaited(_audio.pause());
  }

  void resume() {
    unawaited(_audio.resume());
  }

  void dispose() {
    _playbackDelayTimer?.cancel();
    unawaited(_audio.stop());
  }

  /// Genera un trackId stabile dal path dell'asset.
  String _trackIdFrom(String assetPath) {
    final name = assetPath.split('/').last;
    return name.replaceAll('.mp3', '').replaceAll('.wav', '');
  }
}
