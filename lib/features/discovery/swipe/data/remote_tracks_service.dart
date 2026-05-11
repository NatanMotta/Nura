import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/models/track.dart';
import '../../../../core/services/supabase_bootstrap.dart';

class RemoteTracksService {
  const RemoteTracksService();

  Future<List<Track>> fetchTracks({int limit = 30}) async {
    if (!SupabaseBootstrap.isInitialized) return const [];

    final client = Supabase.instance.client;

    final rows = await client
        .from('tracks')
        .select('id,title,genre,duration_seconds,storage_path,artist_id,profiles!tracks_artist_id_fkey(display_name)')
        .order('created_at', ascending: false)
        .limit(limit);

    return rows
        .whereType<Map<String, dynamic>>()
        .map(_toTrack)
        .toList(growable: false);
  }

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
      // Temporary bridge: if DB path is previews/<file>, play matching local asset.
      // Full cloud playback will use signed download URLs.
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
