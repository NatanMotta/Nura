import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/artist_pitch_service.dart';
import '../../../../../core/models/track.dart';
import '../../../../shared/domain/label.dart';
import '../../../../shared/domain/user_role.dart';
import '../../../../shared/presentation/providers/user_role_provider.dart';
import '../../../../auth/presentation/auth_providers.dart';
import '../../../../../core/services/supabase_bootstrap.dart';

final artistPitchServiceProvider = Provider<ArtistPitchService>((ref) {
  return const ArtistPitchService();
});

// Resoution provider for current active artist ID (handles Real Auth, Mock Login and Local Mock)
final resolvedArtistIdProvider = FutureProvider<String?>((ref) async {
  final authState = ref.watch(authStateProvider);
  final user = authState.value;

  if (user != null) {
    return user.id;
  }

  // Fallback for Mock Role Login
  final mockRole = ref.watch(userRoleProvider);
  if (mockRole == UserRole.artist) {
    if (SupabaseBootstrap.isInitialized) {
      try {
        final client = Supabase.instance.client;
        final rows = await client
            .from('profiles')
            .select('id')
            .eq('role', 'artist')
            .limit(1)
            .maybeSingle();
        return rows?['id'] as String? ?? 'mock-artist-id';
      } catch (_) {
        return 'mock-artist-id';
      }
    }
    return 'mock-artist-id';
  }

  return null;
});

final artistTracksProvider = FutureProvider.family<List<Track>, String>((ref, artistId) {
  final service = ref.watch(artistPitchServiceProvider);
  return service.fetchArtistTracks(artistId);
});

final availableLabelsProvider = FutureProvider<List<Label>>((ref) {
  final service = ref.watch(artistPitchServiceProvider);
  return service.fetchLabels();
});

final artistPitchesProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, artistId) {
  final service = ref.watch(artistPitchServiceProvider);
  return service.fetchArtistPitches(artistId);
});
