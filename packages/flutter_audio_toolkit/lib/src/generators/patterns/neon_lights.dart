import 'dart:math';

/// Generates neon lights pattern with pulsing, colorful rhythms
double generateNeonLightsPattern(
  double t,
  double timeRatio,
  double frequency,
  Random random,
) {
  // Upbeat tempo for neon club vibes
  final bpm = 128.0;
  final beatDuration = 60000 / bpm;
  final beatPosition = (t % beatDuration) / beatDuration;

  // Pulsing kick on every beat
  double kick = beatPosition < 0.08 ? 0.7 : 0.0;

  // Colorful, pulsing synth layers
  final colors = [
    frequency * 1.0, // Red
    frequency * 1.25, // Orange
    frequency * 1.5, // Yellow
    frequency * 1.75, // Green
    frequency * 2.0, // Blue
    frequency * 2.25, // Purple
  ];

  double neonGlow = 0.0;
  for (int i = 0; i < colors.length; i++) {
    final colorPhase = (t + i * 100) / 1000;
    final pulse = (sin(2 * pi * colorPhase) + 1) / 2;
    neonGlow += 0.15 * pulse * sin(2 * pi * colors[i] * t / 1000);
  }

  // Sparkling high frequencies
  double sparkle = 0.0;
  if (random.nextDouble() > 0.92) {
    sparkle = 0.3 * sin(2 * pi * frequency * 4 * t / 1000);
  }

  // Electric buzz atmosphere
  final buzz =
      0.1 * sin(2 * pi * 60 * t / 1000) * (0.5 + 0.5 * random.nextDouble());

  return (kick + neonGlow.abs() + sparkle.abs() + buzz.abs()).clamp(0.0, 1.0);
}
