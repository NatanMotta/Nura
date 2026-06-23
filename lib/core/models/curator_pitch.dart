class CuratorPitch {
  final String id;
  final String trackId;
  final String artistId;
  final String curatorId;
  final String status; // 'pending', 'accepted', 'rejected', 'feedback_given'
  final String? pitchMessage;
  final DateTime createdAt;

  const CuratorPitch({
    required this.id,
    required this.trackId,
    required this.artistId,
    required this.curatorId,
    required this.status,
    this.pitchMessage,
    required this.createdAt,
  });

  factory CuratorPitch.fromJson(Map<String, dynamic> json) {
    return CuratorPitch(
      id: json['id'] as String,
      trackId: json['track_id'] as String,
      artistId: json['artist_id'] as String,
      curatorId: json['curator_id'] as String,
      status: json['status'] as String,
      pitchMessage: json['pitch_message'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'track_id': trackId,
      'artist_id': artistId,
      'curator_id': curatorId,
      'status': status,
      'pitch_message': pitchMessage,
      'created_at': createdAt.toIso8601String(),
    };
  }

  CuratorPitch copyWith({
    String? id,
    String? trackId,
    String? artistId,
    String? curatorId,
    String? status,
    String? pitchMessage,
    DateTime? createdAt,
  }) {
    return CuratorPitch(
      id: id ?? this.id,
      trackId: trackId ?? this.trackId,
      artistId: artistId ?? this.artistId,
      curatorId: curatorId ?? this.curatorId,
      status: status ?? this.status,
      pitchMessage: pitchMessage ?? this.pitchMessage,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
