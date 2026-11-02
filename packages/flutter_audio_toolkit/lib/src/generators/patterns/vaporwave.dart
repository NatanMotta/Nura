import 'dart:math';

/// Generates vaporwave pattern with dreamy, nostalgic aesthetics
double generateVaporwavePattern(
  double t,
  double timeRatio,
  double frequency,
  Random random,
) {
  // Slower tempo for dreamy feel
  final bpm = 90.0;
  final beatDuration = 60000 / bpm;
  final beatPosition = (t % beatDuration) / beatDuration;

  // Soft, filtered kick
  double kick = beatPosition < 0.06 ? 0.5 : 0.0;

  // Dreamy, detuned synth pad
  final padFreqs = [
    frequency * 0.8,
    frequency,
    frequency * 1.2,
    frequency * 1.6,
  ];
  double pad = 0.0;
  for (final freq in padFreqs) {
    pad += 0.1 * sin(2 * pi * freq * t / 1000);
  }
  pad /= padFreqs.length;

  // Nostalgic melody with pitch drift
  final drift = 0.02 * sin(2 * pi * 0.3 * t / 1000);
  final melodyFreq = frequency * 1.5 * (1 + drift);
  double melody = 0.3 * sin(2 * pi * melodyFreq * t / 1000);

  // Ethereal atmosphere
  double atmosphere =
      0.15 * random.nextDouble() * sin(2 * pi * 0.05 * t / 1000);

  return (kick + pad.abs() + melody.abs() + atmosphere.abs()).clamp(0.0, 1.0);
}
