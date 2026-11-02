import 'dart:math';

/// Generates dubstep pattern with heavy wobbles and drops
double generateDubstepPattern(
  double t,
  double timeRatio,
  double frequency,
  Random random,
) {
  // Dubstep typically runs at 140 BPM
  final bpm = 140.0;
  final beatDuration = 60000 / bpm;

  // Determine section
  String section = 'intro';
  if (timeRatio < 0.25) {
    section = 'intro';
  } else if (timeRatio >= 0.25 && timeRatio < 0.3) {
    section = 'buildup';
  } else if (timeRatio >= 0.3 && timeRatio < 0.6) {
    section = 'drop';
  } else if (timeRatio >= 0.6 && timeRatio < 0.7) {
    section = 'buildup2';
  } else {
    section = 'drop2';
  }

  // Signature dubstep half-time kick/snare pattern
  double kick = 0.0;
  double snare = 0.0;
  if (section == 'drop' || section == 'drop2') {
    final halfTimePattern = (t % (beatDuration * 4)) / (beatDuration * 4);
    if (halfTimePattern < 0.05 ||
        (halfTimePattern >= 0.5 && halfTimePattern < 0.55)) {
      kick = 0.8;
    }
    if (halfTimePattern >= 0.25 && halfTimePattern < 0.3) {
      snare = 0.7;
    }
  }

  // Wobble bass (characteristic dubstep sound)
  double wobble = 0.0;
  if (section == 'drop' || section == 'drop2') {
    // LFO modulated bass frequency
    final lfoRate = 16.0; // 16 Hz wobble
    final lfoValue = (sin(2 * pi * lfoRate * t / 1000) + 1) / 2; // 0 to 1

    // Base frequency modulated by LFO
    final wobbleFreq = frequency * 0.3 * (0.5 + 1.5 * lfoValue);

    // Square wave with filter modulation
    final squareWave = (sin(2 * pi * wobbleFreq * t / 1000) > 0) ? 1.0 : -1.0;
    wobble = 0.7 * squareWave * lfoValue;

    // Add formant filtering effect
    final formantFreq = 200 + 800 * lfoValue;
    final formantGain = 1.0 - exp(-formantFreq / 400);
    wobble *= formantGain;
  }

  // Reese bass (growling sub bass)
  double reese = 0.0;
  if (section == 'drop' || section == 'drop2') {
    final reeseFreq = frequency * 0.25;
    final detunes = [-2.0, -1.0, 0.0, 1.0, 2.0];
    for (final detune in detunes) {
      final detuneFreq = reeseFreq + detune;
      reese += sin(2 * pi * detuneFreq * t / 1000);
    }
    reese = (reese / detunes.length) * 0.4;

    // Add low-pass filtering
    reese *= (1 - exp(-100 / reeseFreq));
  }

  // High-pitched lead (screechy synth)
  double lead = 0.0;
  if (section == 'drop' || section == 'drop2' && random.nextDouble() > 0.8) {
    final leadFreq = frequency * 4 + 200 * sin(2 * pi * t / 500);
    lead = 0.3 * sin(2 * pi * leadFreq * t / 1000);
  }

  // Build-up elements
  double buildup = 0.0;
  if (section == 'buildup' || section == 'buildup2') {
    // Rising noise sweep
    final sweepFreq = 100 + 2000 * ((timeRatio % 0.1) / 0.1);
    buildup = 0.4 * random.nextDouble() * sin(2 * pi * sweepFreq * t / 1000);
  }

  // Snare rolls before drops
  double snareRoll = 0.0;
  if (section == 'buildup' || section == 'buildup2') {
    final rollRate = 32.0; // 32nd notes
    final rollCycle = (t * rollRate / 1000) % 1;
    if (rollCycle < 0.1) {
      snareRoll = 0.5;
    }
  }

  return (kick +
          snare +
          wobble.abs() +
          reese.abs() +
          lead.abs() +
          buildup +
          snareRoll)
      .clamp(0.0, 1.0);
}
