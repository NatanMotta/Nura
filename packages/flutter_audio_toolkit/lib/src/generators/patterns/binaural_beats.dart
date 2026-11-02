import 'dart:math';

/// Generates binaural beats pattern for meditation
double generateBinauralBeatsPattern(double t, double frequency) {
  // Binaural beats with slight frequency difference
  final leftFreq = frequency;
  final rightFreq = frequency + 10; // 10 Hz difference for alpha waves

  // Simulate the beating effect
  final beatFreq = (rightFreq - leftFreq).abs();
  final beatPattern = sin(2 * pi * beatFreq * t / 1000);
  final carrier = sin(2 * pi * leftFreq * t / 1000);

  return 0.3 + 0.2 * (carrier * beatPattern).abs();
}
