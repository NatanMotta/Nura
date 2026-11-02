import 'dart:math';

/// Generates ocean waves pattern for nature sounds
double generateOceanPattern(double t, Random random) {
  // Ocean with multiple wave frequencies
  final bigWaves = 0.6 * sin(2 * pi * t / 8000); // 8-second waves
  final mediumWaves = 0.3 * sin(2 * pi * t / 3000); // 3-second waves
  final smallWaves = 0.2 * sin(2 * pi * t / 1000); // 1-second waves
  final foam = 0.1 * random.nextDouble(); // Random foam/bubbles

  final amplitude =
      (bigWaves.abs() + mediumWaves.abs() + smallWaves.abs()) / 3 + foam;
  return amplitude + 0.2; // Increased baseline for better audibility
}
