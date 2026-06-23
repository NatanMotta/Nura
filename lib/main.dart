import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app/nura_app.dart';
import 'core/services/supabase_bootstrap.dart';
import 'core/services/hardware_audio_context_manager.dart';
import 'core/services/push_notification_service.dart';
import 'features/discovery/swipe/presentation/widgets/music_card.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  await SupabaseBootstrap.initialize();
  await preloadLiquidGlassShader();
  await HardwareAudioContextManager.initializeAndObserve();

  // Inizializza Firebase e le Notifiche
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await PushNotificationService().init();
  } catch (e) {
    debugPrint('Errore inizializzazione Firebase/Push: $e');
  }

  runApp(const ProviderScope(child: NuraApp()));
}
