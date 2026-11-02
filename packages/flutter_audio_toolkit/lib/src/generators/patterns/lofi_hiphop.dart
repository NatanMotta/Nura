import 'dart:math';

/// Generates lo-fi hip hop pattern with chill vibes and vinyl crackle
double generateLofiHipHopPattern(
  double t,
  double timeRatio,
  double frequency,
  Random random,
) {
  // Lo-fi hip hop typically runs at 70-90 BPM, let's use 85 BPM
  final bpm = 85.0;
  final beatDuration = 60000 / bpm;
  final beatPosition = (t % beatDuration) / beatDuration;

  // Laid-back kick pattern (slightly behind the beat)
  final kickOffset = 0.02; // Slight delay for that laid-back feel
  double kick = 0.0;
  if (beatPosition >= kickOffset && beatPosition < (kickOffset + 0.1)) {
    kick = 0.6; // Softer kick than trap/EDM
  }

  // Snare on beats 2 and 4 (also slightly behind)
  final snarePattern = (t % (beatDuration * 2)) / (beatDuration * 2);
  double snare = 0.0;
  if (snarePattern >= (0.5 + kickOffset) &&
      snarePattern < (0.5 + kickOffset + 0.08)) {
    snare = 0.5;
  }

  // Jazz-influenced hi-hats (swing rhythm)
  final hiHatFreq = bpm / 60 * 2; // 8th notes with swing
  final hiHatCycle = (t * hiHatFreq / 1000) % 1;
  double hiHat = 0.0;
  // Add swing feel (long-short pattern)
  final swingFactor = 0.67; // Typical swing ratio
  if (hiHatCycle < 0.05 ||
      (hiHatCycle >= swingFactor && hiHatCycle < swingFactor + 0.03)) {
    hiHat = 0.25 * (0.7 + 0.3 * random.nextDouble()); // Add slight randomness
  }

  // Warm, filtered bass
  final bassFreq = frequency * 0.25; // Lower octave
  double bass = 0.4 * sin(2 * pi * bassFreq * t / 1000);
  // Apply low-pass filter effect (soften high frequencies)
  bass *= 0.7;

  // Jazzy chord progression (simple piano-like)
  double chords = 0.0;
  final chordPattern = (t % (beatDuration * 8)) / (beatDuration * 8);
  if (chordPattern < 0.25) {
    // Tonic chord
    chords =
        0.3 *
        (sin(2 * pi * frequency * t / 1000) +
            sin(2 * pi * frequency * 1.25 * t / 1000) +
            sin(2 * pi * frequency * 1.5 * t / 1000)) /
        3;
  } else if (chordPattern < 0.5) {
    // Subdominant
    chords =
        0.3 *
        (sin(2 * pi * frequency * 1.33 * t / 1000) +
            sin(2 * pi * frequency * 1.67 * t / 1000)) /
        2;
  } else if (chordPattern < 0.75) {
    // Dominant
    chords =
        0.3 *
        (sin(2 * pi * frequency * 1.5 * t / 1000) +
            sin(2 * pi * frequency * 1.875 * t / 1000)) /
        2;
  }

  // Vinyl crackle and warmth
  double vinyl = 0.1 * random.nextDouble() * 0.5; // Subtle crackle

  // Tape saturation (slight compression/warmth)
  double warmth = 0.05 * sin(2 * pi * 60 * t / 1000); // 60 Hz hum

  // Ambient texture (rain, café sounds, etc.)
  double ambient = 0.0;
  if (random.nextDouble() > 0.98) {
    ambient = 0.15 * random.nextDouble(); // Occasional ambient sounds
  }

  final totalAmplitude =
      kick +
      snare +
      hiHat +
      bass.abs() +
      chords.abs() +
      vinyl +
      warmth.abs() +
      ambient;
  return totalAmplitude.clamp(0.0, 1.0);
}
