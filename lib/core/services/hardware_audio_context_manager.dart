import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'audio_preview_service.dart';

/// Gestore del contesto hardware audio.
/// Si occupa di proteggere l'engine C++ dai furti di priorità dell'OS
/// (es. l'utente apre TikTok o riceve una chiamata) e rinizializza il bus
/// hardware se viene distrutto durante l'ibernazione dell'app.
class HardwareAudioContextManager {
  static Future<void> initializeAndObserve() async {
    try {
      final session = await AudioSession.instance;
      
      // Dichiara formalmente l'intento applicativo all'OS
      await session.configure(const AudioSessionConfiguration.music());
      
      // Intercetta furti o ritorni di priorità dell'Hardware in background
      session.interruptionEventStream.listen((AudioInterruptionEvent event) {
        if (event.begin) {
          // L'hardware ci è stato sottratto (chiamata in ingresso, altro media avviato)
          switch (event.type) {
            case AudioInterruptionType.duck:
              // Abbassamento volume
              break;
            case AudioInterruptionType.pause:
            case AudioInterruptionType.unknown:
              // Sospende immediatamente tramite FFI prima che il bus venga reciso
              AudioPreviewService.instance.safePause();
              break;
          }
        } else {
          // Ripristino del dominio hardware
          _handleHardwareRestoration();
        }
      });
    } catch (e) {
      debugPrint("HardwareAudioContextManager init failed: $e");
    }
  }

  static Future<void> _handleHardwareRestoration() async {
    // Controllo integrità C++
    if (!SoLoud.instance.isInitialized) {
      debugPrint("Engine audio perduto durante l'ibernazione. Re-init...");
      try {
        await SoLoud.instance.init();
        // L'app rimarrà in pausa ma pronta a ripartire,
        // evitando un resume aggressivo non richiesto.
      } catch (e) {
        debugPrint("Impossibile ristabilire il bus audio: $e");
      }
    }
  }
}
