import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/track.dart';

class TrackUploadRepository {
  final SupabaseClient _client;

  TrackUploadRepository(this._client);

  Future<Track> createTrackRecord({
    required String title,
    required String audioStoragePath,
    required String? coverStoragePath,
    required int durationSeconds,
    required String genre,
    required String sourceContentType,
    required bool requiresTranscoding,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Utente non autenticato');

    final payload = <String, dynamic>{
      'artist_id': userId,
      'title': title,
      'genre': genre,
      'duration_seconds': durationSeconds,
      'cover_image_asset': coverStoragePath,
      'source_content_type': sourceContentType,
      'transcoding_status': requiresTranscoding ? 'processing' : 'ready',
      if (requiresTranscoding) 'raw_storage_path': audioStoragePath,
      if (!requiresTranscoding) 'storage_path': audioStoragePath,
    };

    final trackData =
        await _client.from('tracks').insert(payload).select().single();
    return Track.fromJson(trackData);
  }

  Future<List<Track>> getMyTracks() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Utente non autenticato');

    final rows = await _client
        .from('tracks')
        .select()
        .eq('artist_id', userId)
        .order('created_at', ascending: false);
    return rows.map(Track.fromJson).toList(growable: false);
  }
}

final trackUploadRepositoryProvider = Provider<TrackUploadRepository>((ref) {
  return TrackUploadRepository(Supabase.instance.client);
});
