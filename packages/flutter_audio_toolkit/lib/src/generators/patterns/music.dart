import 'dart:math';

/// Generates music-like pattern with beats, crescendos, and variations
double generateMusicPattern(double t, double timeRatio, Random random) {
  // Music-like pattern with beats, crescendos, and variations
  final bassFreq = 60 + 40 * sin(2 * pi * t / 8); // 8-second bass cycle
  final midFreq = 200 + 100 * sin(2 * pi * t / 4); // 4-second mid cycle
  final highFreq = 800 + 400 * sin(2 * pi * t / 2); // 2-second high cycle

  final bass = 0.6 * sin(2 * pi * bassFreq * t / 100);
  final mid = 0.4 * sin(2 * pi * midFreq * t / 100);
  final high = 0.2 * sin(2 * pi * highFreq * t / 100);

  double amplitude = (bass.abs() + mid.abs() + high.abs()) / 3;

  // Ensure some minimum amplitude for music
  amplitude = amplitude * 0.7 + 0.3;

  // Add some dynamics
  if (timeRatio < 0.1 || timeRatio > 0.9) {
    amplitude *=
        timeRatio < 0.1 ? timeRatio * 10 : (1 - timeRatio) * 10; // Fade in/out
  }

  // Add random variations to make different URLs produce different results
  amplitude += (random.nextDouble() - 0.5) * 0.1; // ±5% random variation

  return amplitude;
}
