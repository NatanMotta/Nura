import 'dart:math';

/// Generates house music pattern with steady 4/4 beats
double generateHouseMusicPattern(
  double t,
  double timeRatio,
  double frequency,
  Random random,
) {
  // Classic house tempo 128 BPM
  final bpm = 128.0;
  final beatDuration = 60000 / bpm;
  final beatPosition = (t % beatDuration) / beatDuration;

  // Four-on-the-floor kick
  double kick = beatPosition < 0.08 ? 0.8 : 0.0;

  // Open hi-hat on off-beats
  final offBeat = ((t + beatDuration / 2) % beatDuration) / beatDuration;
  double hiHat = offBeat < 0.05 ? 0.4 : 0.0;

  // Bassline
  final bassFreq = frequency * 0.5;
  double bass = 0.5 * sin(2 * pi * bassFreq * t / 1000);

  // House piano stabs
  double piano = 0.0;
  if (beatPosition > 0.2 && beatPosition < 0.25) {
    piano = 0.6 * sin(2 * pi * frequency * 1.5 * t / 1000);
  }

  return (kick + hiHat + bass.abs() + piano.abs()).clamp(0.0, 1.0);
}
