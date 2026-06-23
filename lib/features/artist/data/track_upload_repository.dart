import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/models/track.dart';

class TrackUploadRepository {
  final SupabaseClient _client;

  TrackUploadRepository(this._client);

  /// Crea il record della traccia nel database DOPO aver caricato i file su Storage/R2
  Future<Track> createTrackRecord({
    required String title,
    required String audioUrl,
    required String coverUrl,
    required int durationSeconds,
    required int bpm,
    required String genre,
    required int previewStartSeconds,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Utente non autenticato');

    final trackData = await _client.from('tracks').insert({
      'artist_id': userId,
      'title': title,
      'audio_url': audioUrl,
      'cover_url': coverUrl,
      'duration_seconds': durationSeconds,
      'bpm': bpm,
      'genre': genre,
      'preview_start_seconds': previewStartSeconds,
      'status': 'ready', // Potrebbe essere 'processing' se serve un encoding remoto
    }).select().single();

    return Track.fromJson(trackData);
  }

  /// Recupera le tracce dell'artista corrente
  Future<List<Track>> getMyTracks() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Utente non autenticato');

    final rows = await _client.from('tracks').select().eq('artist_id', userId).order('created_at', ascending: false);
    return rows.map((row) => Track.fromJson(row)).toList();
  }
}

final trackUploadRepositoryProvider = Provider<TrackUploadRepository>((ref) {
  return TrackUploadRepository(Supabase.instance.client);
});
