import 'dart:math';

/// Generates jazz pattern with improvisation and swing
double generateJazzPattern(double t, double timeRatio, Random random) {
  // Jazz with swing rhythm and improvisation
  final swingBeat = sin(2 * pi * 2.5 * t / 1000); // Swing tempo
  final pianoComping = 0.3 * sin(2 * pi * 200 * t / 1000 + random.nextDouble());
  final bassWalk = 0.4 * sin(2 * pi * 60 * t / 1000);

  // Add improvisation sections with more variation
  final improSection =
      random.nextDouble() < 0.3 ? 0.5 * random.nextDouble() : 0.0;

  final baseAmplitude =
      (swingBeat.abs() + pianoComping.abs() + bassWalk.abs()) / 3;
  return baseAmplitude + improSection + 0.15;
}
