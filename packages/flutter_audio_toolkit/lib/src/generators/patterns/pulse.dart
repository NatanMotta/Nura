import 'dart:math';

/// Generates rhythmic pulse pattern like a heartbeat or drum
double generatePulsePattern(double t, Random random) {
  final pulseRate = 1.2; // 1.2 beats per second (72 BPM)
  final pulseCycle = (t * pulseRate) % 1;

  double amplitude;
  if (pulseCycle < 0.1) {
    amplitude = 0.9; // Strong beat
  } else if (pulseCycle < 0.2) {
    amplitude = 0.3; // Quick decay
  } else if (pulseCycle < 0.5) {
    amplitude = 0.1; // Low level
  } else if (pulseCycle < 0.6) {
    amplitude = 0.6; // Secondary beat
  } else {
    amplitude = 0.05; // Near silence
  }

  // Add some variation
  return amplitude * (0.8 + 0.4 * random.nextDouble());
}
