import 'dart:math';

/// Generates EDM drop pattern with build-ups and explosive drops
double generateEdmDropPattern(
  double t,
  double timeRatio,
  double frequency,
  Random random,
) {
  // EDM typically runs at 128 BPM
  final bpm = 128.0;
  final beatDuration = 60000 / bpm;
  final beatPosition = (t % beatDuration) / beatDuration;

  // Determine phase: build-up, drop, or breakdown
  double phaseMultiplier = 1.0;
  String phase = 'verse';

  if (timeRatio >= 0.2 && timeRatio < 0.3) {
    phase = 'buildup';
    phaseMultiplier = 1.0 + (timeRatio - 0.2) / 0.1 * 3.0; // Build energy
  } else if (timeRatio >= 0.3 && timeRatio < 0.5) {
    phase = 'drop';
    phaseMultiplier = 4.0; // Maximum energy
  } else if (timeRatio >= 0.6 && timeRatio < 0.7) {
    phase = 'buildup2';
    phaseMultiplier = 1.0 + (timeRatio - 0.6) / 0.1 * 4.0;
  } else if (timeRatio >= 0.7 && timeRatio < 0.9) {
    phase = 'drop2';
    phaseMultiplier = 5.0; // Even bigger drop
  }

  // Four-on-the-floor kick pattern
  double kick = beatPosition < 0.1 ? 0.8 : 0.0;

  // Bass line (varies by phase)
  double bass = 0.0;
  if (phase == 'drop' || phase == 'drop2') {
    // Heavy saw bass in drops
    bass = 0.6 * (2 * ((frequency * 0.5 * t / 1000) % 1) - 1).abs();
  } else if (phase == 'buildup' || phase == 'buildup2') {
    // Rising bass in buildup
    final buildupFreq = frequency * 0.5 * (1 + timeRatio);
    bass = 0.4 * sin(2 * pi * buildupFreq * t / 1000);
  }

  // Lead synth (melodic elements)
  double lead = 0.0;
  if (phase == 'drop' || phase == 'drop2') {
    // Aggressive lead in drops
    final leadFreq = frequency * (1 + 0.5 * sin(2 * pi * t / 2000));
    lead = 0.5 * sin(2 * pi * leadFreq * t / 1000);
  }

  // White noise sweeps during buildups
  double whitenoise = 0.0;
  if (phase == 'buildup' || phase == 'buildup2') {
    whitenoise = 0.3 * random.nextDouble();
  }

  // Reverb tail effect
  double reverb = 0.0;
  if (phase == 'drop' || phase == 'drop2') {
    reverb = 0.2 * exp(-(beatPosition * 5)); // Exponential decay
  }

  // Sidechain compression effect (ducking)
  double sidechain = 1.0;
  if (phase == 'drop' || phase == 'drop2') {
    sidechain = 0.3 + 0.7 * exp(-(beatPosition * 8));
  }

  final totalAmplitude =
      (kick + bass.abs() + lead.abs() + whitenoise + reverb) * sidechain;
  return (totalAmplitude * phaseMultiplier).clamp(0.0, 1.0);
}
