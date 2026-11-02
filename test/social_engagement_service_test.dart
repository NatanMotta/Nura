import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nura_app/features/social/data/social_engagement_service.dart';

void main() {
  test('repeated likes use the unique pair and ignore duplicates', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final client = SupabaseClient('http://127.0.0.1:${server.port}', 'test-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false));
    addTearDown(() async {
      await client.dispose();
      await server.close(force: true);
    });
    var inserts = 0;
    server.listen((request) async {
      expect(request.uri.path, '/rest/v1/track_likes');
      expect(request.uri.queryParameters['on_conflict'], 'track_id,user_id');
      expect(request.headers.value('prefer'), contains('resolution=ignore-duplicates'));
      expect(jsonDecode(await utf8.decoder.bind(request).join()),
          {'track_id': 'track-1', 'user_id': 'user-1'});
      inserts++;
      request.response.statusCode = HttpStatus.created;
      await request.response.close();
    });
    final service = SocialEngagementService(client: client);
    for (var i = 0; i < 2; i++) {
      await service.setLike(trackId: 'track-1', userId: 'user-1', shouldLike: true);
    }
    expect(inserts, 2);
  });
}
