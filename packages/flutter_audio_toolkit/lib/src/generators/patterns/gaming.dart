import 'dart:math';

/// Generates gaming pattern optimized for video game soundtracks
double generateGamingPattern(
  double t,
  double timeRatio,
  double frequency,
  Random random,
) {
  // Energetic gaming tempo
  final bpm = 140.0;
  final beatDuration = 60000 / bpm;
  final beatPosition = (t % beatDuration) / beatDuration;

  // Punchy kick
  double kick = beatPosition < 0.09 ? 0.8 : 0.0;

  // 8-bit style lead
  final leadFreq = frequency * 2;
  final squareWave = (sin(2 * pi * leadFreq * t / 1000) > 0) ? 1.0 : -1.0;
  double lead = 0.4 * squareWave;

  // Bass line
  final bassFreq = frequency * 0.5;
  double bass = 0.5 * sin(2 * pi * bassFreq * t / 1000);

  // Power-up effects
  double powerUp = 0.0;
  if (random.nextDouble() > 0.95) {
    powerUp = 0.6 * sin(2 * pi * frequency * 4 * t / 1000);
  }

  // Digital atmosphere
  double digital = 0.1 * (random.nextDouble() - 0.5);

  return (kick + lead.abs() + bass.abs() + powerUp.abs() + digital.abs()).clamp(
    0.0,
    1.0,
  );
}
