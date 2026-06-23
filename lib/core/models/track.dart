import 'package:flutter/material.dart';

class Track {
  final String id;
  final String? artistId;
  final String artist; // Denormalized for UI
  final String track; // title
  final String genre;
  final String dur;
  final int bpm;
  final int hue;
  final Color swatch;
  final String? audioAsset;
  final String? coverAsset;
  
  // Phase 2: Remote Streaming & Social state
  final String? streamingUrl;
  final DateTime? urlExpiryTime;
  final bool isLiked;
  final int likeCount;
  final String status; // 'processing', 'ready', 'archived'

  const Track(
    this.id,
    this.artist,
    this.track,
    this.genre,
    this.bpm,
    this.hue,
    this.swatch,
    this.dur, {
    this.artistId,
    this.audioAsset,
    this.coverAsset,
    this.streamingUrl,
    this.urlExpiryTime,
    this.isLiked = false,
    this.likeCount = 0,
    this.status = 'ready',
  });

  factory Track.fromJson(Map<String, dynamic> json) {
    final int durSecs = json['duration_seconds'] as int? ?? 0;
    final String durString = durSecs > 0 ? '${durSecs ~/ 60}:${(durSecs % 60).toString().padLeft(2, '0')}' : '0:00';

    return Track(
      json['id'] as String,
      json['artist_name'] as String? ?? 'Unknown Artist', // This might come from a joined query
      json['title'] as String? ?? 'Unknown Title',
      json['genre'] as String? ?? 'Various',
      json['bpm'] as int? ?? 120,
      200, // Default or computed later
      Colors.blueGrey, // Default or computed
      durString,
      artistId: json['artist_id'] as String?,
      audioAsset: json['audio_url'] as String?,
      coverAsset: json['cover_url'] as String?,
      status: json['status'] as String? ?? 'ready',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'artist_id': artistId,
      'title': track,
      'genre': genre,
      'bpm': bpm,
      'audio_url': audioAsset, // Fallback for local
      'cover_url': coverAsset,
      'status': status,
    };
  }

  Track copyWith({
    String? id,
    String? artistId,
    String? artist,
    String? track,
    String? genre,
    String? dur,
    int? bpm,
    int? hue,
    Color? swatch,
    String? audioAsset,
    String? coverAsset,
    String? streamingUrl,
    DateTime? urlExpiryTime,
    bool? isLiked,
    int? likeCount,
    String? status,
  }) {
    return Track(
      id ?? this.id,
      artist ?? this.artist,
      track ?? this.track,
      genre ?? this.genre,
      bpm ?? this.bpm,
      hue ?? this.hue,
      swatch ?? this.swatch,
      dur ?? this.dur,
      artistId: artistId ?? this.artistId,
      audioAsset: audioAsset ?? this.audioAsset,
      coverAsset: coverAsset ?? this.coverAsset,
      streamingUrl: streamingUrl ?? this.streamingUrl,
      urlExpiryTime: urlExpiryTime ?? this.urlExpiryTime,
      isLiked: isLiked ?? this.isLiked,
      likeCount: likeCount ?? this.likeCount,
      status: status ?? this.status,
    );
  }
}
