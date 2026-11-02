import 'dart:math';

/// Generates retrowave pattern with sunset-drive aesthetics
double generateRetrowavePattern(
  double t,
  double timeRatio,
  double frequency,
  Random random,
) {
  // Retrowave at 110 BPM
  final bpm = 110.0;
  final beatDuration = 60000 / bpm;
  final beatPosition = (t % beatDuration) / beatDuration;

  // Steady kick pattern
  double kick = beatPosition < 0.08 ? 0.7 : 0.0;

  // Nostalgic bass synth
  final bassFreq = frequency * 0.5;
  double bass = 0.4 * sin(2 * pi * bassFreq * t / 1000);

  // Dreamy lead synth with chorus
  final leadFreq = frequency * 2;
  final chorus1 = sin(2 * pi * leadFreq * 1.02 * t / 1000);
  final chorus2 = sin(2 * pi * leadFreq * 0.98 * t / 1000);
  double lead = 0.3 * (chorus1 + chorus2) / 2;

  // Sunset atmosphere
  double atmosphere = 0.2 * sin(2 * pi * 0.1 * t / 1000);

  return (kick + bass.abs() + lead.abs() + atmosphere.abs()).clamp(0.0, 1.0);
}
