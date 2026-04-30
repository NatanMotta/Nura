import 'package:flutter/material.dart';

import '../../../core/models/genre.dart';
import '../../../core/models/track.dart';
import '../../../core/models/trending.dart';

const List<Track> kTracks = [
  Track('t1', 'Mira Solène', 'Velvet Static', 'dream pop', 92, 332,
      Color(0xFFFF0A75), '2:48'),
  Track('t2', 'Kaspar Vogel', 'Notturno 03', 'neo-classical', 64, 188,
      Color(0xFFACE7D5), '3:31'),
  Track('t3', 'Rōnin Avila', 'Sub Fathom', 'deep house', 124, 260,
      Color(0xFF7C5BFF), '5:12'),
  Track('t4', 'Iva Krause', 'Tempera', 'art folk', 76, 28, Color(0xFFFF8A3D),
      '3:04'),
  Track('t5', 'Polara', 'Soft Machine', 'electro-pop', 108, 332,
      Color(0xFFFF0A75), '3:22'),
  Track('t6', 'Nube Pequeña', 'Madrugada', 'latin alt', 88, 12,
      Color(0xFFFF5A5F), '2:55'),
  Track('t7', 'Theo Halberg', 'Iron Lung', 'post-rock', 112, 200,
      Color(0xFF54B6CC), '4:48'),
];

const List<Genre> kGenres = [
  Genre('g1', 'Dream Pop', 1284, 332),
  Genre('g2', 'Neo-Classical', 412, 188),
  Genre('g3', 'Deep House', 2104, 260),
  Genre('g4', 'Art Folk', 286, 28),
  Genre('g5', 'Latin Alt', 822, 12),
  Genre('g6', 'Post-Rock', 514, 200),
  Genre('g7', 'Electro-Pop', 1670, 332),
  Genre('g8', 'Ambient', 942, 168),
];

const List<Trending> kTrending = [
  Trending(1, 'Polara', 'Soft Machine', '+18', Color(0xFFFF0A75)),
  Trending(2, 'Mira Solène', 'Velvet Static', '+12', Color(0xFFFF0A75)),
  Trending(3, 'Rōnin Avila', 'Sub Fathom', '+7', Color(0xFF7C5BFF)),
  Trending(4, 'Iva Krause', 'Tempera', '+4', Color(0xFFFF8A3D)),
  Trending(5, 'Theo Halberg', 'Iron Lung', '−1', Color(0xFF54B6CC)),
];
