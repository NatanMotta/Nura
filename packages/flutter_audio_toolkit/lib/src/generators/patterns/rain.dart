import 'dart:math';

/// Generates rain pattern for ambient sound
double generateRainPattern(double t, Random random) {
  // Rain with varying intensity
  final baseIntensity =
      0.3 + 0.2 * sin(2 * pi * t / 10000); // 10-second intensity cycle
  final raindrops = random.nextDouble() < 0.8 ? random.nextDouble() * 0.3 : 0.0;
  final heavyDrops =
      random.nextDouble() < 0.1 ? random.nextDouble() * 0.4 : 0.0;

  return baseIntensity + raindrops + heavyDrops;
}
