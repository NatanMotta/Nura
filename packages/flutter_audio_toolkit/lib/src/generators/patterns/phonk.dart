import 'dart:math';

/// Generates phonk pattern with dark, aggressive Memphis rap style
double generatePhonkPattern(
  double t,
  double timeRatio,
  double frequency,
  Random random,
) {
  // Phonk tempo around 140 BPM
  final bpm = 140.0;
  final beatDuration = 60000 / bpm;
  final beatPosition = (t % beatDuration) / beatDuration;

  // Heavy, distorted kick
  double kick = beatPosition < 0.1 ? 0.9 : 0.0;

  // Dark, Memphis-style hi-hats (triplet feel)
  final hiHatPattern = (t * 3 * bpm / 60000) % 1;
  double hiHat = hiHatPattern < 0.1 ? 0.5 : 0.0;

  // Aggressive 808 bass
  final bassFreq = frequency * 0.25;
  double bass = 0.7 * sin(2 * pi * bassFreq * t / 1000);

  // Dark melody (minor key)
  final melodyFreq = frequency * 1.2; // Minor third
  double melody = 0.4 * sin(2 * pi * melodyFreq * t / 1000);

  // Vinyl crackle
  double vinyl = 0.15 * random.nextDouble();

  // Distorted atmosphere
  double distortion = 0.2 * (random.nextDouble() - 0.5);

  return (kick + hiHat + bass.abs() + melody.abs() + vinyl + distortion.abs())
      .clamp(0.0, 1.0);
}
