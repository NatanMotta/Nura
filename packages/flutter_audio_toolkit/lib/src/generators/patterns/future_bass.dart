import 'dart:math';

/// Generates future bass pattern with melodic drops and emotional builds
double generateFutureBassPattern(
  double t,
  double timeRatio,
  double frequency,
  Random random,
) {
  // Future bass typically runs at 140-160 BPM, let's use 150 BPM
  final bpm = 150.0;
  final beatDuration = 60000 / bpm;
  final beatPosition = (t % beatDuration) / beatDuration;

  // Determine section: intro, buildup, drop, breakdown
  String section = 'intro';
  double sectionMultiplier = 1.0;

  if (timeRatio < 0.2) {
    section = 'intro';
    sectionMultiplier = 0.6;
  } else if (timeRatio >= 0.2 && timeRatio < 0.3) {
    section = 'buildup';
    sectionMultiplier = 0.8 + (timeRatio - 0.2) / 0.1 * 1.5;
  } else if (timeRatio >= 0.3 && timeRatio < 0.55) {
    section = 'drop';
    sectionMultiplier = 2.3;
  } else if (timeRatio >= 0.55 && timeRatio < 0.65) {
    section = 'breakdown';
    sectionMultiplier = 0.7;
  } else if (timeRatio >= 0.65 && timeRatio < 0.75) {
    section = 'buildup2';
    sectionMultiplier = 0.9 + (timeRatio - 0.65) / 0.1 * 2.0;
  } else {
    section = 'drop2';
    sectionMultiplier = 2.8;
  }

  // Kick pattern (less aggressive than EDM, more bouncy)
  double kick = 0.0;
  if (section == 'drop' || section == 'drop2') {
    kick = beatPosition < 0.08 ? 0.7 : 0.0;
  } else if (section == 'intro' || section == 'breakdown') {
    // Softer kick in quieter sections
    kick = beatPosition < 0.06 ? 0.4 : 0.0;
  }

  // Supersaw lead (characteristic future bass sound)
  double supersaw = 0.0;
  if (section == 'drop' || section == 'drop2') {
    // Multiple detuned sawtooth waves
    final baseFreq = frequency * 2; // Higher octave for lead
    final detunes = [-0.05, -0.02, 0.0, 0.02, 0.05, 0.08];
    for (final detune in detunes) {
      final detuneFreq = baseFreq * (1 + detune);
      final sawValue = 2 * ((detuneFreq * t / 1000) % 1) - 1;
      supersaw += sawValue;
    }
    supersaw = (supersaw / detunes.length) * 0.6;

    // Add portamento (pitch sliding)
    final slideAmount = sin(2 * pi * t / 1000) * 0.1;
    supersaw *= (1 + slideAmount);
  }
  // Emotional chord progression
  double chords = 0.0;
  if (section != 'drop' && section != 'drop2') {
    // Lush pad chords in non-drop sections
    final chordFreqs = [
      frequency * 0.8,
      frequency,
      frequency * 1.25,
      frequency * 1.6,
    ];

    for (final freq in chordFreqs) {
      chords += 0.15 * sin(2 * pi * freq * t / 1000);
    }
    chords /= chordFreqs.length;
  }

  // Sub bass (wobbly LFO modulation)
  double subBass = 0.0;
  if (section == 'drop' || section == 'drop2') {
    final lfoRate = 8.0; // LFO at 8 Hz
    final lfoAmount = 0.5 + 0.5 * sin(2 * pi * lfoRate * t / 1000);
    final subFreq = frequency * 0.25;
    subBass = 0.4 * sin(2 * pi * subFreq * t / 1000) * lfoAmount;
  }

  // Vocal chops (simulated)
  double vocals = 0.0;
  if (section == 'breakdown' && random.nextDouble() > 0.9) {
    vocals = 0.3 * sin(2 * pi * frequency * 1.2 * t / 1000);
  }

  // Side-chain compression (pumping effect)
  double sidechain = 1.0;
  if (section == 'drop' || section == 'drop2') {
    sidechain = 0.4 + 0.6 * exp(-beatPosition * 6);
  }

  // Reverb and atmosphere
  double atmosphere = 0.0;
  if (section == 'buildup' || section == 'buildup2') {
    atmosphere = 0.2 * random.nextDouble() * (timeRatio % 0.1) / 0.1;
  }

  final totalAmplitude =
      (kick +
          supersaw.abs() +
          chords.abs() +
          subBass.abs() +
          vocals.abs() +
          atmosphere) *
      sidechain;
  return (totalAmplitude * sectionMultiplier).clamp(0.0, 1.0);
}
