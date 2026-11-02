import 'dart:math';

/// Generates heartbeat pattern for relaxation
double generateHeartbeatPattern(double t, Random random) {
  // Realistic heartbeat at ~70 BPM
  final heartRate = 1.17; // 70 BPM = 1.17 beats per second
  final heartCycle = (t * heartRate) % 1;

  if (heartCycle < 0.15) {
    // Systolic beat (lub)
    return 0.8 + 0.2 * random.nextDouble();
  } else if (heartCycle < 0.25) {
    // Quick decay
    return 0.3 * (1 - (heartCycle - 0.15) / 0.1);
  } else if (heartCycle < 0.4) {
    // Diastolic beat (dub)
    return 0.5 + 0.2 * random.nextDouble();
  } else if (heartCycle < 0.5) {
    // Quick decay
    return 0.2 * (1 - (heartCycle - 0.4) / 0.1);
  } else {
    // Quiet period
    return 0.02 + 0.03 * random.nextDouble();
  }
}
