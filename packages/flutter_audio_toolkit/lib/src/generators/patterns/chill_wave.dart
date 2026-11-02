import 'dart:math';

/// Generates chill wave pattern with dreamy, relaxed summer vibes
double generateChillWavePattern(
  double t,
  double timeRatio,
  double frequency,
  Random random,
) {
  // Relaxed tempo
  final bpm = 95.0;
  final beatDuration = 60000 / bpm;
  final beatPosition = (t % beatDuration) / beatDuration;

  // Soft kick
  double kick = beatPosition < 0.07 ? 0.4 : 0.0;

  // Dreamy synth chords
  final chordFreqs = [frequency * 0.9, frequency * 1.1, frequency * 1.4];
  double chords = 0.0;
  for (final freq in chordFreqs) {
    chords += 0.2 * sin(2 * pi * freq * t / 1000);
  }
  chords /= chordFreqs.length;

  // Gentle lead melody
  final leadFreq = frequency * 2;
  double lead = 0.25 * sin(2 * pi * leadFreq * t / 1000);

  // Summer atmosphere
  double atmosphere = 0.1 * sin(2 * pi * 0.05 * t / 1000);

  // Vinyl warmth
  double warmth = 0.05 * random.nextDouble();

  return (kick + chords.abs() + lead.abs() + atmosphere.abs() + warmth).clamp(
    0.0,
    1.0,
  );
}
