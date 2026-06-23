import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  final SupabaseClient _client;
  ArtistStatsService(this._client);

  Future<NuuraScore> getArtistNuuraScore(String artistId) async {
    final response = await _client
        .from('curator_pitches_view')
        .select()
        .eq('artist_id', artistId)
        .eq('status', 'feedback_given');

    final pitches = List<Map<String, dynamic>>.from(response);
    
    if (pitches.isEmpty) {
      return NuuraScore.empty();
    }

    int totalL = 0;
    int totalV = 0;
    int totalP = 0;
    int totalM = 0;

    for (var pitch in pitches) {
      totalL += (pitch['lyrics_score'] as int? ?? 0);
      totalV += (pitch['vibe_score'] as int? ?? 0);
      totalP += (pitch['production_score'] as int? ?? 0);
      totalM += (pitch['market_potential_score'] as int? ?? 0);
    }

    final count = pitches.length;
    final lAvg = (totalL / count).round();
    final vAvg = (totalV / count).round();
    final pAvg = (totalP / count).round();
    final mAvg = (totalM / count).round();
    
    final overall = ((lAvg + vAvg + pAvg + mAvg) / 4).round();

    return NuuraScore(
      totalScore: overall,
      lyricsScore: lAvg,
      vibeScore: vAvg,
      productionScore: pAvg,
      marketPotentialScore: mAvg,
      totalFeedbacks: count,
    );
  }

  Future<NuuraScore> getTrackNuuraScore(String trackId) async {
    final response = await _client
        .from('curator_pitches_view')
        .select()
        .eq('track_id', trackId)
        .eq('status', 'feedback_given');

    final pitches = List<Map<String, dynamic>>.from(response);
    if (pitches.isEmpty) return NuuraScore.empty();

    int totalL = 0, totalV = 0, totalP = 0, totalM = 0;
    for (var pitch in pitches) {
      totalL += (pitch['lyrics_score'] as int? ?? 0);
      totalV += (pitch['vibe_score'] as int? ?? 0);
      totalP += (pitch['production_score'] as int? ?? 0);
      totalM += (pitch['market_potential_score'] as int? ?? 0);
    }

    final count = pitches.length;
    final lAvg = (totalL / count).round();
    final vAvg = (totalV / count).round();
    final pAvg = (totalP / count).round();
    final mAvg = (totalM / count).round();
    final overall = ((lAvg + vAvg + pAvg + mAvg) / 4).round();

    return NuuraScore(
      totalScore: overall,
      lyricsScore: lAvg,
      vibeScore: vAvg,
      productionScore: pAvg,
      marketPotentialScore: mAvg,
      totalFeedbacks: count,
    );
  }
}

final artistStatsServiceProvider = Provider<ArtistStatsService>((ref) {
  return ArtistStatsService(Supabase.instance.client);
});

final artistNuuraScoreProvider = FutureProvider.family<NuuraScore, String>((ref, artistId) async {
  final service = ref.read(artistStatsServiceProvider);
  return service.getArtistNuuraScore(artistId);
});
