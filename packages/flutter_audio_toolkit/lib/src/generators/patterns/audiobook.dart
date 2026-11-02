import 'dart:math';

/// Generates audiobook pattern with consistent speech flow
double generateAudiobookPattern(double t, Random random) {
  // Very consistent speech pattern for audiobooks
  final speechCycle = (t * 3) % 1; // Standard reading pace

  if (speechCycle < 0.05) {
    // Very brief pauses for punctuation
    return 0.05 + random.nextDouble() * 0.05;
  } else {
    // Consistent narration with slight variations
    final baseLevel = 0.5;
    final emphasis =
        0.1 * sin(2 * pi * speechCycle * 6); // Slight emphasis pattern
    final naturalVariation = 0.05 * (random.nextDouble() - 0.5);

    return baseLevel + emphasis + naturalVariation;
  }
}
