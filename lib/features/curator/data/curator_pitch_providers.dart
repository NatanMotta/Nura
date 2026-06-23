import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'curator_pitch_service.dart';

final pendingPitchesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final service = ref.read(curatorPitchServiceProvider);
  return service.fetchPendingPitches();
});

final evaluatedPitchesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final service = ref.read(curatorPitchServiceProvider);
  return service.fetchEvaluatedPitches();
});
