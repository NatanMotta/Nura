import 'dart:math';

import 'package:flutter_audio_toolkit/src/generators/patterns/pulse.dart';

/// Generates rock music with heavy beats and sustained notes
double generateRockPattern(double t, double timeRatio, Random random) {
  // Rock music with strong beats and guitar riffs
  final drumBeat = generatePulsePattern(t * 1.5, random); // Faster drum beat
  final bassGuitar = 0.5 * sin(2 * pi * 80 * t / 1000);
  final electricGuitar =
      0.6 * sin(2 * pi * 300 * t / 1000 + random.nextDouble());

  // Add power chord sections
  final powerChordCycle = (t * 0.25) % 1; // Every 4 seconds
  final powerChordAmp = powerChordCycle < 0.5 ? 0.8 : 0.4;

  return ((drumBeat + bassGuitar.abs() + electricGuitar.abs()) / 3) *
          powerChordAmp +
      0.2;
}
