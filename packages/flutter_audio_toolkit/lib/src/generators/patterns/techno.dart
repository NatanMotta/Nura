import 'dart:math';

/// Generates techno pattern with driving repetitive beats
double generateTechnoPattern(
  double t,
  double timeRatio,
  double frequency,
  Random random,
) {
  // Fast techno tempo 132 BPM
  final bpm = 132.0;
  final beatDuration = 60000 / bpm;
  final beatPosition = (t % beatDuration) / beatDuration;

  // Driving kick pattern
  double kick = beatPosition < 0.08 ? 0.8 : 0.0;

  // Industrial hi-hats
  final hiHatPattern = (t * 4 * bpm / 60000) % 1;
  double hiHat = hiHatPattern < 0.05 ? 0.3 : 0.0;

  // Repetitive bass synth
  final bassFreq = frequency * 0.4;
  double bass = 0.6 * sin(2 * pi * bassFreq * t / 1000);

  // Driving lead synth
  final leadFreq = frequency * 2;
  double lead = 0.4 * sin(2 * pi * leadFreq * t / 1000);

  return (kick + hiHat + bass.abs() + lead.abs()).clamp(0.0, 1.0);
}
