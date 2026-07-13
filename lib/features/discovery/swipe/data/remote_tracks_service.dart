import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/models/track.dart';
import '../../../../core/services/supabase_bootstrap.dart';

class RemoteTracksService {
  const RemoteTracksService();

  static List<Track>? _cachedTracks;
  static DateTime? _cacheCreatedAt;
  static const _cacheTtl = Duration(minutes: 5);
  static List<Track>? get cachedTracks => _cachedTracks;

  static void clearCache() {
    _cachedTracks = null;
    _cacheCreatedAt = null;
  }

  Future<List<Track>> fetchTracks(
      {int limit = 30, bool forceRefresh = false}) async {
    final cacheIsFresh = _cacheCreatedAt != null &&
        DateTime.now().difference(_cacheCreatedAt!) < _cacheTtl;
    if (!forceRefresh &&
        cacheIsFresh &&
        _cachedTracks != null &&
        _cachedTracks!.isNotEmpty) {
      return _cachedTracks!;
    }
    if (!SupabaseBootstrap.isInitialized) return _demoTracks;

    final client = Supabase.instance.client;

    final rows = await client
        .from('tracks')
        .select(
            'id,title,genre,duration_seconds,storage_path,cover_image_asset,transcoding_status,artist_id,profiles!tracks_artist_id_fkey(display_name)')
        .eq('transcoding_status', 'ready')
        .not('storage_path', 'is', null)
        .order('created_at', ascending: false)
        .limit(limit);

    final remote = rows
        .whereType<Map<String, dynamic>>()
        .map(_toTrack)
        .where((track) =>
            track.artistId != null &&
            track.artistId!.isNotEmpty &&
            track.artist.trim().isNotEmpty &&
            track.artist != 'Unknown Artist')
        .toList(growable: false);

    if (remote.isEmpty) {
      clearCache();
      return const [];
    }

    _cachedTracks = remote;
    _cacheCreatedAt = DateTime.now();
    return remote;
  }

  static final List<Track> _demoTracks = [
    Track('demo_1', 'Nura Demo', 'Midnight Circuit', 'Electronic', 100, 220,
        const Color(0xFF6C63FF), '2:30',
        audioAsset: 'assets/audio/preview_audio_1.mp3',
        coverAsset:
            'assets/images/labels/annie-spratt-0ZPSX_mQ3xI-unsplash.jpg'),
    Track('demo_2', 'Nura Demo', 'Sunset Groove', 'Lo-Fi', 100, 45,
        const Color(0xFFFF6B6B), '2:15',
        audioAsset: 'assets/audio/preview_audio_2.mp3',
        coverAsset:
            'assets/images/labels/jason-leung-wmyE5IBiOmo-unsplash.jpg'),
    Track('demo_3', 'Nura Demo', 'Urban Flow', 'Hip-Hop', 100, 180,
        const Color(0xFF43C59E), '1:58',
        audioAsset: 'assets/audio/preview_audio_3.mp3',
        coverAsset:
            'assets/images/labels/jean-philippe-delberghe-75xPHEQBmvA-unsplash.jpg'),
    Track('demo_4', 'Nura Demo', 'Neon Rain', 'Synthwave', 100, 300,
        const Color(0xFFFF9F43), '2:44',
        audioAsset: 'assets/audio/preview_audio_4.mp3',
        coverAsset:
            'assets/images/labels/joel-filipe-QwoNAhbmLLo-unsplash.jpg'),
    Track('demo_5', 'Nura Demo', 'Deep Horizon', 'Deep House', 100, 200,
        const Color(0xFF5F27CD), '3:10',
        audioAsset: 'assets/audio/preview_audio_5.mp3',
        coverAsset:
            'assets/images/labels/milad-fakurian-E8Ufcyxz514-unsplash.jpg'),
    Track('demo_6', 'Nura Demo', 'Crystal Wave', 'Ambient', 100, 120,
        const Color(0xFF00D2D3), '2:55',
        audioAsset: 'assets/audio/preview_audio_6.mp3',
        coverAsset:
            'assets/images/labels/milad-fakurian-PGdW_bHDbpI-unsplash.jpg'),
    Track('demo_7', 'Nura Demo', 'Street Pulse', 'Trap', 100, 160,
        const Color(0xFFEE5A24), '1:45',
        audioAsset: 'assets/audio/preview_audio_7.mp3',
        coverAsset: 'assets/images/labels/mymind-tZCrFpSNiIQ-unsplash.jpg'),
    Track('demo_8', 'Nura Demo', 'Astral Drift', 'Chillout', 100, 90,
        const Color(0xFF0652DD), '3:22',
        audioAsset: 'assets/audio/preview_audio_8.mp3',
        coverAsset:
            'assets/images/labels/pawel-czerwinski-6lQDFGOB1iw-unsplash.jpg'),
  ];

  Track _toTrack(Map<String, dynamic> row) {
    final id = (row['id'] as String?) ?? 'track_unknown';
    final title = (row['title'] as String?) ?? 'Untitled';
    final genre = (row['genre'] as String?) ?? 'demo';
    final durationSeconds = (row['duration_seconds'] as int?) ?? 15;
    final audioUrl = row['storage_path'] as String?;
    final coverUrl = row['cover_image_asset'] as String?;
    final localAudioAsset = _localAssetFromStoragePath(audioUrl);
    final localCoverAsset = _localCoverFromStoragePath(audioUrl) ?? coverUrl;
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
      audioAsset: SupabaseBootstrap.resolveR2Url(audioUrl) ?? localAudioAsset,
      coverAsset: SupabaseBootstrap.resolveR2Url(coverUrl) ?? localCoverAsset,
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
      'preview_audio_2.mp3':
          'assets/images/labels/jason-leung-wmyE5IBiOmo-unsplash.jpg',
      'preview_audio_3.mp3':
          'assets/images/labels/jean-philippe-delberghe-75xPHEQBmvA-unsplash.jpg',
      'preview_audio_4.mp3':
          'assets/images/labels/joel-filipe-QwoNAhbmLLo-unsplash.jpg',
      'preview_audio_5.mp3':
          'assets/images/labels/milad-fakurian-E8Ufcyxz514-unsplash.jpg',
      'preview_audio_6.mp3':
          'assets/images/labels/milad-fakurian-PGdW_bHDbpI-unsplash.jpg',
      'preview_audio_7.mp3':
          'assets/images/labels/mymind-tZCrFpSNiIQ-unsplash.jpg',
      'preview_audio_8.mp3':
          'assets/images/labels/pawel-czerwinski-6lQDFGOB1iw-unsplash.jpg',
      'preview_audio_9.mp3':
          'assets/images/labels/pawel-czerwinski-ruJm3dBXCqw-unsplash.jpg',
      'preview_audio_10.mp3':
          'assets/images/labels/scott-webb-mV9-1XjnM4Y-unsplash.jpg',
      'preview_audio_11.mp3':
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
    return '$m:$s';
  }
}
