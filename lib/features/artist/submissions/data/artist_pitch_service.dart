import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/models/track.dart';
import '../../../../core/services/supabase_bootstrap.dart';
import '../../../shared/domain/label.dart';

class ArtistPitchService {
  const ArtistPitchService();

  SupabaseClient? get _client =>
      SupabaseBootstrap.isInitialized ? Supabase.instance.client : null;

  // 1. Fetch tracks owned by this artist
  Future<List<Track>> fetchArtistTracks(String artistId) async {
    final client = _client;
    if (client == null) return const [];

    final rows = await client
        .from('tracks')
        .select('id,title,genre,duration_seconds,storage_path,artist_id,profiles!tracks_artist_id_fkey(display_name)')
        .eq('artist_id', artistId)
        .order('created_at', ascending: false);

    return rows
        .whereType<Map<String, dynamic>>()
        .map(_toTrack)
        .toList(growable: false);
  }

  // 2. Fetch all labels to pitch to
  Future<List<Label>> fetchLabels() async {
    final client = _client;
    if (client == null) return const [];

    // Query labels joining the owner's profiles.image_asset (logo path)
    final rows = await client
        .from('labels')
        .select('id,name,city,bio,profiles!labels_owner_id_fkey(image_asset)');

    return rows.whereType<Map<String, dynamic>>().map((row) {
      final id = row['id'] as String? ?? '';
      final name = row['name'] as String? ?? '';
      final city = row['city'] as String? ?? '';
      final bio = row['bio'] as String? ?? '';
      
      final profile = row['profiles'];
      final logoAsset = profile is Map<String, dynamic>
          ? profile['image_asset'] as String?
          : null;

      return Label(
        id: id,
        name: name,
        city: city,
        bio: bio,
        logoAsset: logoAsset ?? 'assets/images/labels/annie-spratt-0ZPSX_mQ3xI-unsplash.jpg',
      );
    }).toList(growable: false);
  }

  // 3. Send a new pitch request
  Future<void> sendPitch({
    required String artistId,
    required String labelId,
    required String trackId,
  }) async {
    final client = _client;
    if (client == null) return;

    await client.from('pitch_requests').insert({
      'artist_id': artistId,
      'label_id': labelId,
      'track_id': trackId,
      'status': 'sent',
    });
  }

  // 4. Fetch already sent pitches for this artist with nested joined details
  Future<List<Map<String, dynamic>>> fetchArtistPitches(String artistId) async {
    final client = _client;
    if (client == null) return const [];

    final rows = await client
        .from('pitch_requests')
        .select('id,status,created_at,track:tracks(title,genre),label:labels(name,city,profiles!labels_owner_id_fkey(image_asset))')
        .eq('artist_id', artistId)
        .order('created_at', ascending: false);

    return rows.whereType<Map<String, dynamic>>().toList();
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
      'preview_audio_1.mp3': 'assets/images/labels/annie-spratt-0ZPSX_mQ3xI-unsplash.jpg',
      'preview_audio_2.mp3': 'assets/images/labels/jason-leung-wmyE5IBiOmo-unsplash.jpg',
      'preview_audio_3.mp3': 'assets/images/labels/jean-philippe-delberghe-75xPHEQBmvA-unsplash.jpg',
      'preview_audio_4.mp3': 'assets/images/labels/joel-filipe-QwoNAhbmLLo-unsplash.jpg',
      'preview_audio_5.mp3': 'assets/images/labels/milad-fakurian-E8Ufcyxz514-unsplash.jpg',
      'preview_audio_6.mp3': 'assets/images/labels/milad-fakurian-PGdW_bHDbpI-unsplash.jpg',
      'preview_audio_7.mp3': 'assets/images/labels/mymind-tZCrFpSNiIQ-unsplash.jpg',
      'preview_audio_8.mp3': 'assets/images/labels/pawel-czerwinski-6lQDFGOB1iw-unsplash.jpg',
      'preview_audio_9.mp3': 'assets/images/labels/pawel-czerwinski-ruJm3dBXCqw-unsplash.jpg',
      'preview_audio_10.mp3': 'assets/images/labels/scott-webb-mV9-1XjnM4Y-unsplash.jpg',
      'preview_audio_11.mp3': 'assets/images/labels/annie-spratt-0ZPSX_mQ3xI-unsplash.jpg',
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
    return '$m:$s';
  }
}
