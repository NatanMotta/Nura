import 'dart:math';

/// Generates dark ambient pattern with mysterious, haunting tones
double generateDarkAmbientPattern(
  double t,
  double timeRatio,
  double frequency,
  Random random,
) {
  // Very slow evolving pattern
  final evolveRate = 0.02; // 50 second cycle
  final phase = (t * evolveRate / 1000) % 1;

  // Deep, rumbling drone
  final droneFreq = frequency * 0.3;
  double drone = 0.4 * sin(2 * pi * droneFreq * t / 1000);

  // Haunting high frequencies
  final hauntFreq = frequency * 3 + 100 * sin(2 * pi * 0.1 * t / 1000);
  double haunt = 0.2 * sin(2 * pi * hauntFreq * t / 1000) * phase;

  // Mysterious textures
  double mystery = 0.0;
  if (random.nextDouble() > 0.97) {
    mystery = 0.3 * random.nextDouble();
  }

  // Evolving pad
  double pad =
      0.25 * sin(2 * pi * frequency * 0.7 * t / 1000) * (0.5 + 0.5 * phase);

  return (drone.abs() + haunt.abs() + mystery + pad.abs()).clamp(0.0, 1.0);
}
