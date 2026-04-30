import 'package:flutter/material.dart';

class Track {
  final String id, artist, track, genre, dur;
  final int bpm, hue;
  final Color swatch;
  const Track(this.id, this.artist, this.track, this.genre, this.bpm, this.hue,
      this.swatch, this.dur);
}
