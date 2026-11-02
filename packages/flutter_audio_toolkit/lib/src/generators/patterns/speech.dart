import 'dart:math';

/// Generates speech-like pattern with pauses and varying intensity
double generateSpeechPattern(double t, Random random) {
  final speechCycle = (t * 3) % 1; // 3 speech cycles per second

  if (speechCycle < 0.3) {
    // Silence (pause between words)
    return 0.05 + random.nextDouble() * 0.05; // Very low background noise
  } else if (speechCycle < 0.7) {
    // Speech segment with consonants and vowels
    final intensity = 0.3 + 0.4 * sin(2 * pi * speechCycle * 5);
    return intensity * (0.8 + 0.2 * random.nextDouble());
  } else {
    // Transition to silence
    return 0.2 * (1 - (speechCycle - 0.7) / 0.3);
  }
}
