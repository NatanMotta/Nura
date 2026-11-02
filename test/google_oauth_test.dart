import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nura_app/features/auth/data/supabase_auth_repository.dart';

import 'support/memory_auth_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('plugins.flutter.io/url_launcher');

  test('Google login opens Supabase OAuth with the app callback and PKCE', () async {
    final client = SupabaseClient('https://example.invalid', 'test-key',
        authOptions: AuthClientOptions(
          autoRefreshToken: false,
          authFlowType: AuthFlowType.pkce,
          pkceAsyncStorage: MemoryAuthStorage(),
        ));
    addTearDown(client.dispose);
    Uri? launched;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'launch') {
        launched = Uri.parse((call.arguments as Map)['url'] as String);
        return true;
      }
      return null;
    });
    addTearDown(() => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null));
    await SupabaseAuthRepository(client: client).signInWithGoogle();
    expect(launched?.host, 'example.invalid');
    expect(launched?.path, '/auth/v1/authorize');
    expect(launched?.queryParameters['provider'], 'google');
    expect(launched?.queryParameters['redirect_to'], 'it.nuralabs.nura://login-callback/');
    expect(launched?.queryParameters['code_challenge'], isNotEmpty);
    expect(launched?.queryParameters['code_challenge_method'], 's256');
  });
}
