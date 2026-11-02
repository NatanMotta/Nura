import 'dart:math';

/// Generates sudden bursts of activity followed by quiet periods
double generateBurstPattern(double t, Random random) {
  final burstCycle = (t * 0.5) % 1; // 0.5 bursts per second

  if (burstCycle < 0.2) {
    // Intense burst
    return 0.7 + 0.3 * random.nextDouble();
  } else if (burstCycle < 0.4) {
    // Quick decay
    return 0.5 * (1 - (burstCycle - 0.2) / 0.2);
  } else {
    // Quiet period with occasional small spikes
    return random.nextDouble() < 0.05 ? 0.3 * random.nextDouble() : 0.02;
  }
}
