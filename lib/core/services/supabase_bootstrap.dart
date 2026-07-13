import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseBootstrap {
  static bool _initialized = false;

  static bool get isInitialized => _initialized;
  static late final String r2PublicUrl;

  static String? resolveR2Url(String? storagePath) {
    if (storagePath == null || storagePath.trim().isEmpty) return null;
    final value = storagePath.trim();
    if (value.startsWith('http://') ||
        value.startsWith('https://') ||
        value.startsWith('assets/')) {
      return value;
    }
    final base = r2PublicUrl.endsWith('/')
        ? r2PublicUrl.substring(0, r2PublicUrl.length - 1)
        : r2PublicUrl;
    final path = value.startsWith('/') ? value.substring(1) : value;
    return '$base/$path';
  }

  static Future<void> initialize() async {
    if (_initialized) return;

    const url = String.fromEnvironment('SUPABASE_URL');
    const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

    // Fallback impostato fisso sull'URL pubblico R2 di NURA
    const r2Url = String.fromEnvironment('R2_PUBLIC_URL',
        defaultValue: 'https://pub-b27bd4af51ca43b5991a770ebeed7cdc.r2.dev');
    r2PublicUrl = r2Url;

    if (url.isEmpty || anonKey.isEmpty) {
      debugPrint(
        'SupabaseBootstrap: SUPABASE_URL o SUPABASE_ANON_KEY mancanti. '
        'Avvio app in modalita local/mock.',
      );
      return;
    }

    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
      authOptions: const FlutterAuthClientOptions(autoRefreshToken: true),
    );

    _initialized = true;
  }
}
