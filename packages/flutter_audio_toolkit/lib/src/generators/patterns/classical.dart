import 'dart:math';

/// Generates classical music with orchestral dynamics
double generateClassicalPattern(double t, double timeRatio, Random random) {
  // Classical music with orchestral sections and dynamics
  final stringSection = 0.3 * sin(2 * pi * 200 * t / 1000);
  final woodwindSection = 0.2 * sin(2 * pi * 400 * t / 1000 + pi / 4);
  final brassSection = 0.4 * sin(2 * pi * 100 * t / 1000 + pi / 2);

  // Dynamic changes throughout the piece
  double dynamicLevel = 0.5;
  if (timeRatio < 0.2) {
    dynamicLevel = 0.3 + 0.4 * timeRatio / 0.2; // Gradual opening
  } else if (timeRatio > 0.6 && timeRatio < 0.8) {
    dynamicLevel = 0.7 + 0.3 * sin(2 * pi * (timeRatio - 0.6) / 0.2); // Climax
  } else if (timeRatio > 0.9) {
    dynamicLevel = 0.7 * (1 - (timeRatio - 0.9) / 0.1); // Fade to end
  }

  final amplitude =
      (stringSection.abs() + woodwindSection.abs() + brassSection.abs()) / 3;
  return amplitude * dynamicLevel + 0.1;
}
