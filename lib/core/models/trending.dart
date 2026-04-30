import 'package:flutter/material.dart';

class Trending {
  final int rank;
  final String artist, track, delta;
  final Color swatch;
  const Trending(this.rank, this.artist, this.track, this.delta, this.swatch);
}
