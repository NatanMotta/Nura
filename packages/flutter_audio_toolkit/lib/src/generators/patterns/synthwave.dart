import 'dart:math';

/// Generates synthwave pattern with retro 80s style oscillations
double generateSynthwavePattern(
  double t,
  double timeRatio,
  double frequency,
  Random random,
) {
  // Synthwave typically runs at 100-120 BPM, let's use 110 BPM
  final bpm = 110.0;
  final beatDuration = 60000 / bpm;
  final beatPosition = (t % beatDuration) / beatDuration;

  // Driving kick pattern (four-on-the-floor with slight variation)
  double kick = beatPosition < 0.08 ? 0.7 : 0.0;

  // Gated reverb snare (very 80s)
  final snarePattern = (t % (beatDuration * 2)) / (beatDuration * 2);
  double snare = 0.0;
  if (snarePattern >= 0.5 && snarePattern < 0.6) {
    // Gated reverb effect
    final gatePos = (snarePattern - 0.5) * 10;
    snare = 0.6 * exp(-gatePos * 2) * (sin(gatePos * 20) + 1) / 2;
  }

  // Analog-style bass synth (Moog-like)
  final bassFreq = frequency * 0.5;
  double bass = 0.0;
  // Square wave with filter sweep
  final filterCutoff = 200 + 300 * sin(2 * pi * t / 4000); // Slow filter sweep
  final squareWave = (sin(2 * pi * bassFreq * t / 1000) > 0) ? 1.0 : -1.0;
  bass = 0.5 * squareWave * (1 - exp(-filterCutoff / 1000));

  // Arpeggiated lead synth (classic 80s sound)
  final arpeggioPattern = (t % (beatDuration * 4)) / (beatDuration * 4);
  double arpeggio = 0.0;
  final arpeggioNotes = [1.0, 1.25, 1.5, 2.0]; // Major triad + octave
  final noteIndex =
      (arpeggioPattern * arpeggioNotes.length).floor() % arpeggioNotes.length;
  final noteFreq = frequency * arpeggioNotes[noteIndex];

  // Sawtooth wave with chorus effect
  final sawWave = 2 * ((noteFreq * t / 1000) % 1) - 1;
  final chorus1 = sin(2 * pi * noteFreq * 1.01 * t / 1000); // Slightly detuned
  final chorus2 = sin(2 * pi * noteFreq * 0.99 * t / 1000); // Slightly detuned
  arpeggio = 0.4 * (sawWave + chorus1 + chorus2) / 3;

  // Pad synth (lush background)
  double pad = 0.0;
  final padFreqs = [
    frequency * 0.75,
    frequency,
    frequency * 1.25,
    frequency * 1.5,
  ];
  for (final freq in padFreqs) {
    pad += 0.1 * sin(2 * pi * freq * t / 1000);
  }
  pad /= padFreqs.length;

  // Add analog warmth and slight detuning
  final analogWarmth = 0.02 * sin(2 * pi * 50 * t / 1000); // Power supply hum
  final detuning = 0.01 * sin(2 * pi * 0.5 * t / 1000); // Slow pitch drift

  // Tape saturation (smooth limiting)
  double totalAmplitude =
      kick + snare + bass.abs() + arpeggio.abs() + pad + analogWarmth.abs();
  totalAmplitude = totalAmplitude + detuning;
  // Soft saturation curve (tape-like)
  if (totalAmplitude > 0.8) {
    // Approximate tanh function for soft saturation
    final x = (totalAmplitude - 0.8) * 5;
    final tanhApprox = (exp(x) - exp(-x)) / (exp(x) + exp(-x));
    totalAmplitude = 0.8 + 0.2 * tanhApprox;
  }

  return totalAmplitude.clamp(0.0, 1.0);
}
