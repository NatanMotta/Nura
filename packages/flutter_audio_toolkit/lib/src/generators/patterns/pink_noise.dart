import 'dart:math';

/// Generates pink noise pattern with frequency-dependent amplitude
double generatePinkNoisePattern(double t, Random random) {
  // Pink noise with 1/f frequency distribution
  final lowFreq = 0.4 * sin(2 * pi * 50 * t / 1000);
  final midFreq = 0.2 * sin(2 * pi * 200 * t / 1000);
  final highFreq = 0.1 * sin(2 * pi * 800 * t / 1000);

  return (lowFreq.abs() + midFreq.abs() + highFreq.abs()) +
      0.2 * random.nextDouble();
}
