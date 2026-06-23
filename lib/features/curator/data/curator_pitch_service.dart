import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final curatorPitchServiceProvider = Provider<CuratorPitchService>((ref) {
  return CuratorPitchService(Supabase.instance.client);
});

class CuratorPitchService {
  final SupabaseClient _client;

  CuratorPitchService(this._client);

  // Fetch pending pitches for a curator
  Future<List<Map<String, dynamic>>> fetchPendingPitches() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _client
        .from('curator_pitches_view')
        .select()
        .eq('curator_id', userId)
        .eq('status', 'pending')
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  // Fetch evaluated pitches for a curator
  Future<List<Map<String, dynamic>>> fetchEvaluatedPitches() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _client
        .from('curator_pitches_view')
        .select()
        .eq('curator_id', userId)
        .eq('status', 'feedback_given')
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  // Submit feedback/score
  Future<void> submitScore({
    required String pitchId,
    required int lyricsScore,
    required int vibeScore,
    required int productionScore,
    required int marketScore,
    String? feedback,
  }) async {
    await _client.from('curator_pitches').update({
      'lyrics_score': lyricsScore,
      'vibe_score': vibeScore,
      'production_score': productionScore,
      'market_potential_score': marketScore,
      'feedback_message': feedback,
      'status': 'feedback_given',
    }).eq('id', pitchId);
  }
}
