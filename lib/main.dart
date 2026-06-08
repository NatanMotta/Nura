import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/nura_app.dart';
import 'core/services/supabase_bootstrap.dart';
import 'core/services/hardware_audio_context_manager.dart';
import 'features/discovery/swipe/presentation/widgets/music_card.dart';

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

  runApp(const ProviderScope(child: NuraApp()));
}
