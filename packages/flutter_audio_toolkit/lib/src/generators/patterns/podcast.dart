import 'dart:math';

/// Generates podcast/radio pattern with clear speech
double generatePodcastPattern(double t, Random random) {
  // Clear speech with consistent levels and occasional pauses
  final speechCycle = (t * 2.5) % 1; // Slightly faster than normal speech

  if (speechCycle < 0.1) {
    // Brief pause
    return 0.02 + random.nextDouble() * 0.03;
  } else if (speechCycle < 0.8) {
    // Clear, consistent speech
    final consonantVowelPattern = sin(2 * pi * speechCycle * 8);
    return 0.4 + 0.2 * consonantVowelPattern.abs() + 0.1 * random.nextDouble();
  } else {
    // End of sentence/thought
    return 0.3 * (1 - (speechCycle - 0.8) / 0.2);
  }
}
