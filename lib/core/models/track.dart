import 'package:flutter/material.dart';

class Track {
  final String id;
  final String? artistId;
  final String artist;
  final String track;
  final String genre;
  final String dur;
  final int bpm;
  final int hue;
  final Color swatch;
  final String? audioAsset;
  final String? coverAsset;

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
  });
}
