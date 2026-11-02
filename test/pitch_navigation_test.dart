import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nura_app/app/theme/app_theme.dart';
import 'package:nura_app/features/auth/presentation/auth_providers.dart';
import 'package:nura_app/features/artist/submissions/presentation/screens/artist_pitch_screen.dart';
import 'package:nura_app/features/user/shell/user_shell.dart';

import 'support/memory_auth_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await Supabase.initialize(
      url: 'https://example.invalid',
      anonKey: 'test-key',
      accessToken: () async => 'test-token',
      debug: false,
      authOptions: FlutterAuthClientOptions(
        localStorage: const EmptyLocalStorage(),
        pkceAsyncStorage: MemoryAuthStorage(),
        detectSessionInUri: false,
      ),
    );
  });

  testWidgets('music note opens Pitch in the user shell', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [authStateProvider.overrideWith((ref) => Stream.value(null))],
      child: const MaterialApp(
        home: UserShell(vibe: NuraVibe.premium, accent: Colors.pink, waveform: 'bars'),
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byIcon(Icons.music_note_rounded).last);
    await tester.pump();
    expect(find.byType(ArtistPitchScreen), findsOneWidget);
    expect(find.text('Invio Pitch'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
  });
}
