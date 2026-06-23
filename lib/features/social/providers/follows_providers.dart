import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/follows_repository.dart';

final followsRepositoryProvider = Provider<FollowsRepository>((ref) {
  return FollowsRepository(Supabase.instance.client);
});

final isFollowingProvider = FutureProvider.family<bool, String>((ref, targetUserId) async {
  final repo = ref.watch(followsRepositoryProvider);
  return repo.isFollowing(targetUserId);
});

final followersCountProvider = FutureProvider.family<int, String>((ref, targetUserId) async {
  final repo = ref.watch(followsRepositoryProvider);
  return repo.getFollowersCount(targetUserId);
});
