import 'package:supabase_flutter/supabase_flutter.dart';

class FollowsRepository {
  final SupabaseClient _client;

  FollowsRepository(this._client);

  Future<void> followUser(String targetUserId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Non autenticato');

    await _client.from('follows').insert({
      'follower_id': userId,
      'following_id': targetUserId,
    });
  }

  Future<void> unfollowUser(String targetUserId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Non autenticato');

    await _client
        .from('follows')
        .delete()
        .eq('follower_id', userId)
        .eq('following_id', targetUserId);
  }

  Future<bool> isFollowing(String targetUserId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;

    final response = await _client
        .from('follows')
        .select('created_at')
        .eq('follower_id', userId)
        .eq('following_id', targetUserId)
        .maybeSingle();

    return response != null;
  }

  Future<int> getFollowersCount(String userId) async {
    final count = await _client
        .from('follows')
        .count(CountOption.exact)
        .eq('following_id', userId);
    return count;
  }
}
