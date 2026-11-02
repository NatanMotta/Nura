import 'dart:math';

/// Generates cyberpunk pattern with dystopian, futuristic vibes
double generateCyberpunkPattern(
  double t,
  double timeRatio,
  double frequency,
  Random random,
) {
  // Industrial-influenced tempo
  final bpm = 120.0;
  final beatDuration = 60000 / bpm;
  final beatPosition = (t % beatDuration) / beatDuration;

  // Harsh industrial kick
  double kick = beatPosition < 0.1 ? 0.8 : 0.0;

  // Glitchy, distorted elements
  double glitch = 0.0;
  if (random.nextDouble() > 0.95) {
    glitch = 0.6 * (random.nextDouble() - 0.5);
  }

  // Dark, modulated bass
  final bassFreq = frequency * 0.4;
  final modulation = 1 + 0.3 * sin(2 * pi * 0.5 * t / 1000);
  final darkBass = 0.5 * sin(2 * pi * bassFreq * modulation * t / 1000);

  // Harsh synth lead
  final leadFreq = frequency * 2;
  final distortion = sin(2 * pi * leadFreq * t / 1000);
  final harshLead = 0.4 * ((distortion > 0) ? 1.0 : -1.0);

  // Atmospheric pad
  double atmosphere =
      0.2 *
      sin(2 * pi * frequency * 0.75 * t / 1000) *
      sin(2 * pi * 0.1 * t / 1000);

  return (kick + glitch + darkBass.abs() + harshLead.abs() + atmosphere.abs())
      .clamp(0.0, 1.0);
}
