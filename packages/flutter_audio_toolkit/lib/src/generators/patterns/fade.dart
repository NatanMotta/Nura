import 'dart:math';

/// Generates gradual fade in and out pattern
double generateFadePattern(double t, double timeRatio, double frequency) {
  final baseWave = 0.5 + 0.3 * sin(2 * pi * frequency * t / 100);

  if (timeRatio < 0.3) {
    // Fade in
    return baseWave * (timeRatio / 0.3);
  } else if (timeRatio < 0.7) {
    // Sustain
    return baseWave;
  } else {
    // Fade out
    return baseWave * (1 - (timeRatio - 0.7) / 0.3);
  }
}
