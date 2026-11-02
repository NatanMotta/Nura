import 'dart:math';

/// Generates white noise pattern for sound masking
double generateWhiteNoisePattern(Random random) {
  return 0.3 + 0.4 * random.nextDouble();
}
