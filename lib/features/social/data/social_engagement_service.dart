import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/supabase_bootstrap.dart';

class EngagementCounts {
  final int likes;
  final int saves;
  final int comments;

  const EngagementCounts({
    this.likes = 0,
    this.saves = 0,
    this.comments = 0,
  });
}

class TrackComment {
  final String id;
  final String trackId;
  final String userId;
  final String body;
  final DateTime createdAt;
  final String? authorName;

  const TrackComment({
    required this.id,
    required this.trackId,
    required this.userId,
    required this.body,
    required this.createdAt,
    required this.authorName,
  });
}

class SocialEngagementService {
  const SocialEngagementService();

  SupabaseClient? get _client =>
      SupabaseBootstrap.isInitialized ? Supabase.instance.client : null;

  Future<Map<String, EngagementCounts>> fetchCountsForTrackIds(
    List<String> trackIds,
  ) async {
    if (trackIds.isEmpty) return const {};
    final client = _client;
    if (client == null) return const {};

    final rows = await client
        .from('track_engagement_stats')
        .select('track_id,likes_count,saves_count,comments_count')
        .inFilter('track_id', trackIds);

    final result = <String, EngagementCounts>{};
    for (final row in rows) {
      final trackId = row['track_id'] as String?;
      if (trackId == null) continue;
      result[trackId] = EngagementCounts(
        likes: (row['likes_count'] as num?)?.toInt() ?? 0,
        saves: (row['saves_count'] as num?)?.toInt() ?? 0,
        comments: (row['comments_count'] as num?)?.toInt() ?? 0,
      );
    }
    return result;
  }

  Future<Set<String>> fetchUserLikedTrackIds(
    String userId,
    List<String> trackIds,
  ) async {
    if (trackIds.isEmpty) return <String>{};
    final client = _client;
    if (client == null) return <String>{};

    final rows = await client
        .from('track_likes')
        .select('track_id')
        .eq('user_id', userId)
        .inFilter('track_id', trackIds);

    return rows
        .whereType<Map<String, dynamic>>()
        .map((r) => r['track_id'] as String?)
        .whereType<String>()
        .toSet();
  }

  Future<Set<String>> fetchUserSavedTrackIds(
    String userId,
    List<String> trackIds,
  ) async {
    if (trackIds.isEmpty) return <String>{};
    final client = _client;
    if (client == null) return <String>{};

    final rows = await client
        .from('track_saves')
        .select('track_id')
        .eq('user_id', userId)
        .inFilter('track_id', trackIds);

    return rows
        .whereType<Map<String, dynamic>>()
        .map((r) => r['track_id'] as String?)
        .whereType<String>()
        .toSet();
  }

  Future<void> setLike({
    required String trackId,
    required String userId,
    required bool shouldLike,
  }) async {
    final client = _client;
    if (client == null) return;

    if (shouldLike) {
      await client.from('track_likes').upsert({
        'track_id': trackId,
        'user_id': userId,
      });
    } else {
      await client
          .from('track_likes')
          .delete()
          .eq('track_id', trackId)
          .eq('user_id', userId);
    }
  }

  Future<void> setSave({
    required String trackId,
    required String userId,
    required bool shouldSave,
  }) async {
    final client = _client;
    if (client == null) return;

    if (shouldSave) {
      await client.from('track_saves').upsert({
        'track_id': trackId,
        'user_id': userId,
      });
    } else {
      await client
          .from('track_saves')
          .delete()
          .eq('track_id', trackId)
          .eq('user_id', userId);
    }
  }

  Future<List<TrackComment>> fetchComments(
    String trackId, {
    int limit = 40,
  }) async {
    final client = _client;
    if (client == null) return const [];

    final rows = await client
        .from('track_comments')
        .select('id,track_id,user_id,body,created_at,profiles!track_comments_user_id_fkey(display_name)')
        .eq('track_id', trackId)
        .eq('is_deleted', false)
        .order('created_at', ascending: false)
        .limit(limit);

    return rows.whereType<Map<String, dynamic>>().map((row) {
      final profile = row['profiles'];
      final authorName = profile is Map<String, dynamic>
          ? profile['display_name'] as String?
          : null;
      return TrackComment(
        id: row['id'] as String? ?? '',
        trackId: row['track_id'] as String? ?? trackId,
        userId: row['user_id'] as String? ?? '',
        body: row['body'] as String? ?? '',
        createdAt:
            DateTime.tryParse(row['created_at'] as String? ?? '') ?? DateTime.now(),
        authorName: authorName,
      );
    }).toList(growable: false);
  }

  Future<void> addComment({
    required String trackId,
    required String userId,
    required String body,
  }) async {
    final client = _client;
    if (client == null) return;

    final trimmed = body.trim();
    if (trimmed.isEmpty) return;

    await client.from('track_comments').insert({
      'track_id': trackId,
      'user_id': userId,
      'body': trimmed,
    });
  }
}
