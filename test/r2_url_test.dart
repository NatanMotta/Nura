import 'package:flutter_test/flutter_test.dart';
import 'package:nura_app/core/services/supabase_bootstrap.dart';

void main() {
  setUpAll(() {
    SupabaseBootstrap.r2PublicUrl = 'https://media.example.com///';
  });

  test('resolves stored R2 keys without duplicate separators', () {
    expect(SupabaseBootstrap.resolveR2Url(' /audio/track.mp3 '),
        'https://media.example.com/audio/track.mp3');
    expect(SupabaseBootstrap.resolveR2Url('covers/image.jpg'),
        'https://media.example.com/covers/image.jpg');
  });

  test('preserves signed URLs and bundled assets', () {
    const signed = 'https://media.example.com/track.mp3?signature=a%2Fb';
    expect(SupabaseBootstrap.resolveR2Url(signed), signed);
    expect(SupabaseBootstrap.resolveR2Url('assets/audio/demo.mp3'),
        'assets/audio/demo.mp3');
  });

  test('missing media stays unavailable', () {
    expect(SupabaseBootstrap.resolveR2Url(null), isNull);
    expect(SupabaseBootstrap.resolveR2Url('  '), isNull);
  });
}
