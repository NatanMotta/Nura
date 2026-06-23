import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/data/track_repository.dart';
import '../data/social_engagement_service.dart';

final socialEngagementServiceProvider = Provider<SocialEngagementService>((ref) {
  return const SocialEngagementService();
});

class SocialEngagementNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    // Initial state is just empty void
  }

  /// Esegue un toggle del Like con pattern Optimistic Update
  Future<void> toggleLike(String trackId) async {
    final trackRepo = ref.read(trackRepositoryProvider.notifier);
    final track = trackRepo.getTrack(trackId);
    if (track == null) return;

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      debugPrint('User not logged in, cannot toggle like.');
      return;
    }

    final bool isCurrentlyLiked = track.isLiked;
    final bool nextLikedState = !isCurrentlyLiked;

    // 1. Snapshot locale
    final backupTrack = track.copyWith();

    // 2. Mutazione Ottimistica in memoria (Aggiornamento istantaneo UI)
    trackRepo.updateTrack(trackId, (t) => t.copyWith(
      isLiked: nextLikedState,
      likeCount: nextLikedState ? t.likeCount + 1 : (t.likeCount > 0 ? t.likeCount - 1 : 0),
    ));

    try {
      // 3. Chiamata asincrona al server
      final service = ref.read(socialEngagementServiceProvider);
      await service.setLike(trackId: trackId, userId: userId, shouldLike: nextLikedState);
      // Se non lancia eccezioni, il server ha confermato! Lo snapshot di backup viene scartato (GC).
    } catch (e) {
      // 4. Fallimento della rete: Meccanismo di Rollback!
      debugPrint('Errore durante il toggleLike: $e - Avvio rollback!');
      trackRepo.putTrack(backupTrack);
      // TODO: Emettere un segnale globale (es. per mostrare uno SnackBar all'utente)
      rethrow;
    }
  }
}

final socialEngagementProvider = AsyncNotifierProvider<SocialEngagementNotifier, void>(() {
  return SocialEngagementNotifier();
});
