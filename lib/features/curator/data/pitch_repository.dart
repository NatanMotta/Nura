import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/models/curator_pitch.dart';

class PitchRepository {
  final SupabaseClient _client;

  PitchRepository(this._client);

  /// Invia un pitch a un curatore
  Future<CuratorPitch> sendPitch({
    required String trackId,
    required String curatorId,
    String? pitchMessage,
  }) async {
    final artistId = _client.auth.currentUser?.id;
    if (artistId == null) throw Exception('Utente non autenticato');

    final pitchData = await _client.from('curator_pitches').insert({
      'track_id': trackId,
      'artist_id': artistId,
      'curator_id': curatorId,
      'pitch_message': pitchMessage,
      'status': 'pending',
    }).select().single();

    return CuratorPitch.fromJson(pitchData);
  }

  /// Recupera i pitch inviati dall'artista corrente
  Future<List<CuratorPitch>> getMySentPitches() async {
    final artistId = _client.auth.currentUser?.id;
    if (artistId == null) throw Exception('Utente non autenticato');

    final rows = await _client.from('curator_pitches').select().eq('artist_id', artistId).order('created_at', ascending: false);
    return rows.map((row) => CuratorPitch.fromJson(row)).toList();
  }

  /// Recupera i pitch ricevuti dal curatore corrente
  Future<List<CuratorPitch>> getPitchesForMe() async {
    final curatorId = _client.auth.currentUser?.id;
    if (curatorId == null) throw Exception('Utente non autenticato');

    final rows = await _client.from('curator_pitches').select().eq('curator_id', curatorId).order('created_at', ascending: false);
    return rows.map((row) => CuratorPitch.fromJson(row)).toList();
  }
}

final pitchRepositoryProvider = Provider<PitchRepository>((ref) {
  return PitchRepository(Supabase.instance.client);
});
