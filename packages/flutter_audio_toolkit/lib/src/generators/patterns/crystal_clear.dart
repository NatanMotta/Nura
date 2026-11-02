import 'dart:math';

/// Generates crystal clear pattern with pristine, bell-like tones
double generateCrystalClearPattern(
  double t,
  double timeRatio,
  double frequency,
  Random random,
) {
  // Clean, precise timing
  final bpm = 120.0;
  final beatDuration = 60000 / bpm;
  final beatPosition = (t % beatDuration) / beatDuration;

  // Clean kick
  double kick = beatPosition < 0.06 ? 0.6 : 0.0;

  // Bell-like tones
  final bellFreqs = [frequency, frequency * 2, frequency * 3, frequency * 4];
  double bells = 0.0;
  for (int i = 0; i < bellFreqs.length; i++) {
    final amplitude = 0.3 / (i + 1); // Harmonics decay
    bells +=
        amplitude *
        sin(2 * pi * bellFreqs[i] * t / 1000) *
        exp(-t / (5000 + i * 1000));
  }

  // Crystal sparkles
  double sparkles = 0.0;
  if (random.nextDouble() > 0.93) {
    sparkles = 0.4 * sin(2 * pi * frequency * 6 * t / 1000);
  }

  // Pure atmosphere
  double atmosphere = 0.15 * sin(2 * pi * frequency * 0.5 * t / 1000);

  return (kick + bells.abs() + sparkles.abs() + atmosphere.abs()).clamp(
    0.0,
    1.0,
  );
}
