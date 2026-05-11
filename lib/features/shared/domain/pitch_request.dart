enum PitchVisualStatus {
  sent,
  viewed,
  shortlisted,
  rejected,
}

class PitchRequest {
  final String id;
  final String artistId;
  final String labelId;
  final String trackId;
  final PitchVisualStatus visualStatus;

  const PitchRequest({
    required this.id,
    required this.artistId,
    required this.labelId,
    required this.trackId,
    required this.visualStatus,
  });
}
