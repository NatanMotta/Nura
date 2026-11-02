import 'dart:math';

/// Generates electronic/synthesized music pattern
double generateElectronicPattern(
  double t,
  double timeRatio,
  double frequency,
  Random random,
) {
  // Electronic music with beats, drops, and synthesis
  final beatFreq = 4.0; // 4 beats per second (240 BPM)
  final beatCycle = (t * beatFreq) % 1;

  // Bass line
  final bassAmp = beatCycle < 0.1 ? 0.9 : 0.3 * sin(2 * pi * 60 * t / 1000);

  // Synth lead
  final synthFreq = frequency + 200 * sin(2 * pi * t / 4);
  final synthAmp = 0.4 * sin(2 * pi * synthFreq * t / 1000);

  // Add drops and builds
  double buildupMultiplier = 1.0;
  if (timeRatio > 0.7 && timeRatio < 0.8) {
    // Build up
    buildupMultiplier = 1.0 + 2.0 * (timeRatio - 0.7) / 0.1;
  } else if (timeRatio >= 0.8 && timeRatio < 0.85) {
    // Drop
    buildupMultiplier = 3.0;
  }

  return ((bassAmp.abs() + synthAmp.abs()) / 2) * buildupMultiplier;
}
