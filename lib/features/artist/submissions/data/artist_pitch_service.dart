import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/models/track.dart';
import '../../../../core/services/supabase_bootstrap.dart';
import '../../../shared/domain/label.dart';
import '../../../shared/domain/pitch_request.dart';

class ArtistPitchService {
  const ArtistPitchService();

  SupabaseClient? get _client =>
      SupabaseBootstrap.isInitialized ? Supabase.instance.client : null;

  // 1. Fetch tracks owned by this artist
  Future<List<Track>> fetchArtistTracks(String artistId) async {
    final client = _client;
    if (client == null) return [];

    try {
      final rows = await client
          .from('tracks')
          .select(
              'id,title,genre,duration_seconds,storage_path,artist_id,profiles!tracks_artist_id_fkey(display_name)')
          .eq('artist_id', artistId)
          .order('created_at', ascending: false);

      return rows
          .whereType<Map<String, dynamic>>()
          .map(_toTrack)
          .toList(growable: true);
    } catch (_) {
      return [];
    }
  }

  // 2. Fetch all labels (curators) to pitch to
  Future<List<Label>> fetchLabels() async {
    final client = _client;
    if (client == null) return [];

    try {
      // Per ora peschiamo tutti i profili con role = 'curator'
      final rows = await client
          .from('profiles')
          .select('id,username,display_name,bio')
          .eq('role', 'curator');

      return rows.whereType<Map<String, dynamic>>().map((row) {
        final id = row['id'] as String? ?? '';
        final name = row['display_name'] as String? ??
            row['username'] as String? ??
            'Curator';
        final bio = row['bio'] as String? ?? '';

        return Label(
          id: id,
          name: name,
          city: 'Global',
          bio: bio,
          logoAsset:
              'assets/images/labels/annie-spratt-0ZPSX_mQ3xI-unsplash.jpg', // Placeholder
        );
      }).toList(growable: false);
    } catch (_) {
      return [];
    }
  }

  // 3. Send a new pitch request
  Future<void> sendPitch({
    required String artistId,
    required String labelId,
    required String trackId,
    String? message,
  }) async {
    final client = _client;
    if (client == null || client.auth.currentUser == null) return;

    await client.from('curator_pitches').insert({
      'artist_id': artistId,
      'curator_id': labelId,
      'track_id': trackId,
      'status': 'pending',
      'pitch_message': message,
    });
  }

  // 4. Fetch already sent pitches for this artist
  Future<List<Map<String, dynamic>>> fetchArtistPitches(String artistId) async {
    final client = _client;
    if (client == null) return [];

    try {
      final rows = await client
          .from('curator_pitches')
          .select('id,status,created_at,pitch_message,feedback_message,lyrics_score,vibe_score,production_score,market_potential_score,track:tracks(title,genre),curator:profiles!curator_pitches_curator_id_fkey(display_name)')
          .eq('artist_id', artistId)
          .order('created_at', ascending: false);

      return rows.whereType<Map<String, dynamic>>().map((row) {
         final l = row['lyrics_score'] as int? ?? 0;
         final v = row['vibe_score'] as int? ?? 0;
         final p = row['production_score'] as int? ?? 0;
         final m = row['market_potential_score'] as int? ?? 0;
         final int? nuraScore = (l > 0 || v > 0 || p > 0 || m > 0) ? ((l + v + p + m) / 4).round() : null;

         return {
            'id': row['id'],
            'status': row['status'],
            'created_at': row['created_at'],
            'message': row['pitch_message'],
            'curator_feedback': row['feedback_message'],
            'nura_score': nuraScore,
            'track': {
            'title': row['track']?['title'] ?? 'Untitled',
            'genre': row['track']?['genre'] ?? 'demo',
          },
          'label': {
            'name': row['curator']?['display_name'] ?? 'Curator',
            'city': 'Global',
            'profiles': {
              'image_asset':
                  'assets/images/labels/annie-spratt-0ZPSX_mQ3xI-unsplash.jpg',
            }
          }
        };
      }).toList();
    } catch (_) {
      return [];
    }
  }

  // Mapper derived from RemoteTracksService
  Track _toTrack(Map<String, dynamic> row) {
    final id = (row['id'] as String?) ?? 'track_unknown';
    final title = (row['title'] as String?) ?? 'Untitled';
    final genre = (row['genre'] as String?) ?? 'demo';
    final durationSeconds = (row['duration_seconds'] as int?) ?? 15;
    final storagePath = row['storage_path'] as String?;
    final localAudioAsset = _localAssetFromStoragePath(storagePath);
    final localCoverAsset = _localCoverFromStoragePath(storagePath);
    final artistId = row['artist_id'] as String?;

    final profile = row['profiles'];
    final artistName = profile is Map<String, dynamic>
        ? (profile['display_name'] as String?) ?? 'Unknown Artist'
        : 'Unknown Artist';

    final hue = _hueFromId(id);

    return Track(
      id,
      artistName,
      title,
      genre,
      100,
      hue,
      _colorFromHue(hue),
      _mmss(durationSeconds),
      artistId: artistId,
      audioAsset: localAudioAsset,
      coverAsset: localCoverAsset,
    );
  }

  String? _localAssetFromStoragePath(String? storagePath) {
    if (storagePath == null || storagePath.isEmpty) return null;
    final parts = storagePath.split('/');
    if (parts.isEmpty) return null;
    final fileName = parts.last;
    if (!fileName.toLowerCase().endsWith('.mp3')) return null;
    return 'assets/audio/$fileName';
  }

  String? _localCoverFromStoragePath(String? storagePath) {
    if (storagePath == null || storagePath.isEmpty) return null;
    final fileName = storagePath.split('/').last.toLowerCase();
    const map = <String, String>{
      'preview_audio_1.mp3':
          'assets/images/labels/annie-spratt-0ZPSX_mQ3xI-unsplash.jpg',
    };
    return map[fileName];
  }

  int _hueFromId(String id) {
    var hash = 0;
    for (final code in id.codeUnits) {
      hash = (hash * 31 + code) & 0x7fffffff;
    }
    return hash % 360;
  }

  Color _colorFromHue(int hue) {
    final hsl = HSLColor.fromAHSL(1, hue.toDouble(), 0.70, 0.56);
    return hsl.toColor();
  }

  String _mmss(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '${m}:${s}';
  }
}
