import 'dart:math';

/// Generates trap beat pattern with heavy 808s and hi-hats
double generateTrapBeatPattern(
  double t,
  double timeRatio,
  double frequency,
  Random random,
) {
  // Trap typically runs at 140-180 BPM, let's use 150 BPM
  final bpm = 150.0;
  final beatDuration = 60000 / bpm; // Duration of one beat in ms
  final beatPosition = (t % beatDuration) / beatDuration;

  // 808 kick pattern (strong on beats 1 and 3, weaker on 2 and 4)
  final kickPattern = (t % (beatDuration * 4)) / (beatDuration * 4);
  double kick = 0.0;
  if (kickPattern < 0.25 || (kickPattern >= 0.5 && kickPattern < 0.75)) {
    // Strong kicks on beats 1 and 3
    kick = beatPosition < 0.1 ? 0.9 : 0.0;
  } else {
    // Weaker kicks on beats 2 and 4
    kick = beatPosition < 0.05 ? 0.6 : 0.0;
  }

  // Hi-hat pattern (rapid 16th notes with variations)
  final hiHatFreq = bpm / 60 * 4; // 16th notes
  final hiHatCycle = (t * hiHatFreq / 1000) % 1;
  double hiHat = 0.0;
  if (random.nextDouble() > 0.3) {
    // Some randomness in hi-hat pattern
    hiHat = hiHatCycle < 0.1 ? 0.4 : 0.0;
  }

  // Snare on beats 2 and 4
  final snarePattern = (t % (beatDuration * 2)) / (beatDuration * 2);
  double snare = 0.0;
  if (snarePattern >= 0.5) {
    final snarePos = (snarePattern - 0.5) * 2;
    snare = snarePos < 0.15 ? 0.7 : 0.0;
  }

  // Sub bass (low frequency wobble)
  final subBass = 0.3 * sin(2 * pi * 55 * t / 1000); // 55 Hz sub bass

  // Melodic elements (sparse synth hits)
  double melody = 0.0;
  if (timeRatio > 0.25 && random.nextDouble() > 0.95) {
    melody = 0.5 * sin(2 * pi * frequency * t / 1000);
  }

  // Add some reverse reverb effects before drops
  double reverseEffect = 0.0;
  final barPosition = (t % (beatDuration * 16)) / (beatDuration * 16);
  if (barPosition > 0.9) {
    reverseEffect = 0.3 * (barPosition - 0.9) / 0.1;
  }

  return (kick + hiHat + snare + subBass.abs() * 0.5 + melody + reverseEffect)
      .clamp(0.0, 1.0);
}
