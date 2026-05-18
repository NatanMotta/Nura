import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/artist_pitch_service.dart';
import '../../../../../core/models/track.dart';
import '../../../../shared/domain/label.dart';

final artistPitchServiceProvider = Provider<ArtistPitchService>((ref) {
  return const ArtistPitchService();
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
