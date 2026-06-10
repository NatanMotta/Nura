import 'package:flutter_riverpod/flutter_riverpod.dart';

class NuuraScore {
  final int totalScore;
  final int lyricsScore;
  final int vibeScore;
  final int productionScore;
  final int marketPotentialScore;
  final int totalFeedbacks;

  const NuuraScore({
    required this.totalScore,
    required this.lyricsScore,
    required this.vibeScore,
    required this.productionScore,
    required this.marketPotentialScore,
    required this.totalFeedbacks,
  });

  factory NuuraScore.empty() {
    return const NuuraScore(
      totalScore: 0,
      lyricsScore: 0,
      vibeScore: 0,
      productionScore: 0,
      marketPotentialScore: 0,
      totalFeedbacks: 0,
    );
  }
}

class ArtistStatsService {
  Future<NuuraScore> getArtistNuuraScore(String artistId) async {
    // Simula una latenza di rete
    await Future.delayed(const Duration(milliseconds: 800));

    // Dati Mockati (Simulazione aggregazione da tabella curator_feedbacks)
    return const NuuraScore(
      totalScore: 88,
      lyricsScore: 85,
      vibeScore: 92,
      productionScore: 89,
      marketPotentialScore: 86,
      totalFeedbacks: 14,
    );
  }
}

final artistStatsServiceProvider = Provider<ArtistStatsService>((ref) {
  return ArtistStatsService();
});

final artistNuuraScoreProvider = FutureProvider.family<NuuraScore, String>((ref, artistId) async {
  final service = ref.read(artistStatsServiceProvider);
  return service.getArtistNuuraScore(artistId);
});
