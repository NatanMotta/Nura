import 'dart:math';

/// Generates ambient/drone pattern with sustained tones
double generateAmbientPattern(
  double t,
  double timeRatio,
  double frequency,
  Random random,
) {
  // Ambient music with slow evolving textures
  final drone1 =
      0.3 * sin(2 * pi * frequency * t / 2000); // Very slow oscillation
  final drone2 =
      0.2 * sin(2 * pi * (frequency + 5) * t / 3000); // Slight detuning
  final texture = 0.1 * sin(2 * pi * frequency * 2 * t / 5000);

  // Very slow evolution
  final evolution = 0.5 + 0.3 * sin(2 * pi * t / 30000); // 30-second cycle

  return (drone1.abs() + drone2.abs() + texture.abs()) * evolution + 0.1;
}
