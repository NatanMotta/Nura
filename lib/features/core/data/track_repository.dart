import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/track.dart';

/// Single Source of Truth (SSoT) per le tracce musicali.
/// Mantiene un dizionario in RAM indicizzato per UUID.
class TrackRepositoryNotifier extends Notifier<Map<String, Track>> {
  @override
  Map<String, Track> build() {
    return {};
  }

  /// Inserisce o aggiorna una singola traccia nel dizionario globale
  void putTrack(Track track) {
    state = {
      ...state,
      track.id: track,
    };
  }

  /// Inserisce o aggiorna un elenco di tracce
  void putTracks(List<Track> tracks) {
    final newState = Map<String, Track>.from(state);
    for (var track in tracks) {
      newState[track.id] = track;
    }
    state = newState;
  }

  /// Ottiene una traccia dal dizionario, o null se non presente
  Track? getTrack(String id) => state[id];

  /// Aggiorna una traccia ottimisticamente (o dopo risposta del server)
  void updateTrack(String id, Track Function(Track) updater) {
    final track = state[id];
    if (track != null) {
      state = {
        ...state,
        id: updater(track),
      };
    }
  }
}

final trackRepositoryProvider = NotifierProvider<TrackRepositoryNotifier, Map<String, Track>>(() {
  return TrackRepositoryNotifier();
});

/// Provider specifico per osservare una singola traccia in modo reattivo
final trackProvider = Provider.family<Track?, String>((ref, id) {
  final tracksMap = ref.watch(trackRepositoryProvider);
  return tracksMap[id];
});
