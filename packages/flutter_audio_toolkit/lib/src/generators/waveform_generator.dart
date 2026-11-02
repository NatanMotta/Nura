import 'dart:math';
import 'package:flutter_audio_toolkit/src/generators/patterns/ambient.dart';
import 'package:flutter_audio_toolkit/src/generators/patterns/binaural_beats.dart';
import 'package:flutter_audio_toolkit/src/generators/patterns/chill_wave.dart';
import 'package:flutter_audio_toolkit/src/generators/patterns/crystal_clear.dart';
import 'package:flutter_audio_toolkit/src/generators/patterns/cyberpunk.dart';
import 'package:flutter_audio_toolkit/src/generators/patterns/dark_ambient.dart';
import 'package:flutter_audio_toolkit/src/generators/patterns/dubstep.dart';
import 'package:flutter_audio_toolkit/src/generators/patterns/edm_drop.dart';
import 'package:flutter_audio_toolkit/src/generators/patterns/future_bass.dart';
import 'package:flutter_audio_toolkit/src/generators/patterns/gaming.dart';
import 'package:flutter_audio_toolkit/src/generators/patterns/heartbeat.dart';
import 'package:flutter_audio_toolkit/src/generators/patterns/house_music.dart';
import 'package:flutter_audio_toolkit/src/generators/patterns/lofi_hiphop.dart';
import 'package:flutter_audio_toolkit/src/generators/patterns/music.dart';
import 'package:flutter_audio_toolkit/src/generators/patterns/neon_lights.dart';
import 'package:flutter_audio_toolkit/src/generators/patterns/ocean.dart';
import 'package:flutter_audio_toolkit/src/generators/patterns/phonk.dart';
import 'package:flutter_audio_toolkit/src/generators/patterns/pink_noise.dart';
import 'package:flutter_audio_toolkit/src/generators/patterns/pulse.dart';
import 'package:flutter_audio_toolkit/src/generators/patterns/rain.dart';
import 'package:flutter_audio_toolkit/src/generators/patterns/retrowave.dart';
import 'package:flutter_audio_toolkit/src/generators/patterns/speech.dart';
import 'package:flutter_audio_toolkit/src/generators/patterns/synthwave.dart';
import 'package:flutter_audio_toolkit/src/generators/patterns/techno.dart';
import 'package:flutter_audio_toolkit/src/generators/patterns/trap_beat.dart';
import 'package:flutter_audio_toolkit/src/generators/patterns/vaporwave.dart';

import '../models/models.dart';

/// Generator for creating synthetic waveform data for testing and preview purposes
class WaveformGenerator {
  /// Default sample rate for generated audio
  static const int defaultSampleRate = 44100;

  /// Default number of channels for generated audio
  static const int defaultChannels = 2;

  /// Default frequency for wave generation
  static const double defaultFrequency = 440.0;

  /// Generates fake waveform data based on the specified pattern
  ///
  /// [pattern] - Waveform pattern to generate
  /// [durationMs] - Duration of the waveform in milliseconds (default: 30000 = 30 seconds)
  /// [samplesPerSecond] - Number of amplitude samples per second (default: 100)
  /// [frequency] - Base frequency for pattern generation (default: 440.0 Hz)
  /// [sampleRate] - Sample rate in Hz (default: 44100)
  /// [channels] - Number of audio channels (default: 2 for stereo)
  /// [random] - Optional random generator for consistent results (if null, creates new instance)
  ///
  /// Returns a [WaveformData] object containing the generated waveform
  static WaveformData generateFakeWaveform({
    required WaveformPattern pattern,
    int durationMs = 30000, // 30 seconds default
    int samplesPerSecond = 100,
    double frequency = defaultFrequency,
    int sampleRate = defaultSampleRate,
    int channels = defaultChannels,
    Random? random,
  }) {
    if (durationMs <= 0) {
      durationMs = 30000; // Ensure we have a valid duration
    }

    random ??= Random();

    // Calculate number of samples
    final numSamples = (durationMs * samplesPerSecond / 1000).round();

    final List<double> amplitudes = [];

    for (int i = 0; i < numSamples; i++) {
      final double t = (i * durationMs) / numSamples;
      final double timeRatio = i / numSamples;

      double amplitude;
      try {
        amplitude = _generateAmplitudeForPattern(
          pattern,
          t,
          timeRatio,
          frequency,
          random,
        );
      } catch (e) {
        // Fallback to simple sine wave if pattern generation fails
        amplitude = (sin(2 * pi * frequency * t / 1000) + 1) / 2;
      }

      amplitudes.add(amplitude.clamp(0.0, 1.0));
    }
    return WaveformData(
      amplitudes: amplitudes,
      sampleRate: sampleRate,
      durationMs: durationMs,
      channels: channels,
    );
  }

  /// Internal method to generate amplitude for a specific pattern
  static double _generateAmplitudeForPattern(
    WaveformPattern pattern,
    double t,
    double timeRatio,
    double frequency,
    Random random,
  ) {
    switch (pattern) {
      // Basic patterns
      case WaveformPattern.sine:
        return (sin(2 * pi * frequency * t / 1000) + 1) / 2;
      case WaveformPattern.random:
        return random.nextDouble();
      case WaveformPattern.music:
        return generateMusicPattern(t, timeRatio, random);
      case WaveformPattern.speech:
        return generateSpeechPattern(t, random);
      case WaveformPattern.pulse:
        return generatePulsePattern(t, random);

      // Modern Electronic & EDM
      case WaveformPattern.trapBeat:
        return generateTrapBeatPattern(t, timeRatio, frequency, random);
      case WaveformPattern.edmDrop:
        return generateEdmDropPattern(t, timeRatio, frequency, random);
      case WaveformPattern.futureBass:
        return generateFutureBassPattern(t, timeRatio, frequency, random);
      case WaveformPattern.dubstep:
        return generateDubstepPattern(t, timeRatio, frequency, random);
      case WaveformPattern.houseMusic:
        return generateHouseMusicPattern(t, timeRatio, frequency, random);
      case WaveformPattern.techno:
        return generateTechnoPattern(t, timeRatio, frequency, random);

      // Retro & Synthwave
      case WaveformPattern.synthwave:
        return generateSynthwavePattern(t, timeRatio, frequency, random);
      case WaveformPattern.retrowave:
        return generateRetrowavePattern(t, timeRatio, frequency, random);
      case WaveformPattern.vaporwave:
        return generateVaporwavePattern(t, timeRatio, frequency, random);
      case WaveformPattern.cyberpunk:
        return generateCyberpunkPattern(t, timeRatio, frequency, random);
      case WaveformPattern.neonLights:
        return generateNeonLightsPattern(t, timeRatio, frequency, random);

      // Chill & Lo-fi
      case WaveformPattern.lofiHipHop:
        return generateLofiHipHopPattern(t, timeRatio, frequency, random);
      case WaveformPattern.ambient:
        return generateAmbientPattern(t, timeRatio, frequency, random);
      case WaveformPattern.darkAmbient:
        return generateDarkAmbientPattern(t, timeRatio, frequency, random);
      case WaveformPattern.chillWave:
        return generateChillWavePattern(t, timeRatio, frequency, random);

      // Gaming & Digital
      case WaveformPattern.gaming:
        return generateGamingPattern(t, timeRatio, frequency, random);
      case WaveformPattern.digitalGlitch:
        return _generateDigitalGlitch(t, frequency, random);
      case WaveformPattern.crystalClear:
        return generateCrystalClearPattern(t, timeRatio, frequency, random);
      case WaveformPattern.phonk:
        return generatePhonkPattern(t, timeRatio, frequency, random);

      // Nature & Relaxation
      case WaveformPattern.heartbeat:
        return generateHeartbeatPattern(t, random);
      case WaveformPattern.ocean:
        return generateOceanPattern(t, random);
      case WaveformPattern.rain:
        return generateRainPattern(t, random);
      case WaveformPattern.whiteNoise:
        return _generateWhiteNoise(random);
      case WaveformPattern.pinkNoise:
        return generatePinkNoisePattern(t, random);
      case WaveformPattern.binauralBeats:
        return generateBinauralBeatsPattern(t, frequency);

      // Cinematic & Epic
      case WaveformPattern.cinematicEpic:
        return _generateCinematicEpic(t, timeRatio, frequency, random);
      case WaveformPattern.deepBass:
        return _generateDeepBass(t, frequency);
      case WaveformPattern.highEnergy:
        return _generateHighEnergy(t, timeRatio, frequency, random);
    }
  }

  /// Generates a styled waveform with a predefined color scheme
  ///
  /// [pattern] - Waveform pattern to generate
  /// [style] - Predefined style configuration
  /// [durationMs] - Duration of the waveform in milliseconds (default: 30000 = 30 seconds)
  /// [samplesPerSecond] - Number of amplitude samples per second (default: 100)
  /// [frequency] - Base frequency for pattern generation (default: 440.0 Hz)
  /// [sampleRate] - Sample rate in Hz (default: 44100)
  /// [channels] - Number of audio channels (default: 2 for stereo)
  ///
  /// Returns a [WaveformData] object with the specified style
  static WaveformData generateStyledWaveform({
    required WaveformPattern pattern,
    required WaveformStyle style,
    int durationMs = 30000,
    int samplesPerSecond = 100,
    double frequency = defaultFrequency,
    int sampleRate = defaultSampleRate,
    int channels = defaultChannels,
  }) {
    final waveformData = generateFakeWaveform(
      pattern: pattern,
      durationMs: durationMs,
      samplesPerSecond: samplesPerSecond,
      frequency: frequency,
      sampleRate: sampleRate,
      channels: channels,
    );

    return WaveformData(
      amplitudes: waveformData.amplitudes,
      sampleRate: waveformData.sampleRate,
      durationMs: waveformData.durationMs,
      channels: waveformData.channels,
      style: style,
    );
  }

  /// Generates a themed waveform for a specific music genre or style
  static WaveformData generateThemedWaveform({
    required WaveformPattern pattern,
    int durationMs = 30000,
    int samplesPerSecond = 100,
    double frequency = defaultFrequency,
    int sampleRate = defaultSampleRate,
    int channels = defaultChannels,
  }) {
    final waveform = generateFakeWaveform(
      pattern: pattern,
      durationMs: durationMs,
      samplesPerSecond: samplesPerSecond,
      frequency: frequency,
      sampleRate: sampleRate,
      channels: channels,
    );

    // Assign themed style based on pattern
    final themedStyle = _getStyleForPattern(pattern);

    return WaveformData(
      amplitudes: waveform.amplitudes,
      sampleRate: waveform.sampleRate,
      durationMs: waveform.durationMs,
      channels: waveform.channels,
      style: themedStyle,
    );
  }

  /// Gets appropriate style for a given waveform pattern
  static WaveformStyle _getStyleForPattern(WaveformPattern pattern) {
    switch (pattern) {
      case WaveformPattern.cyberpunk:
      case WaveformPattern.neonLights:
      case WaveformPattern.phonk:
        return WaveformColorSchemes.neon;

      case WaveformPattern.ocean:
      case WaveformPattern.rain:
        return WaveformColorSchemes.ocean;

      case WaveformPattern.ambient:
      case WaveformPattern.darkAmbient:
      case WaveformPattern.chillWave:
        return WaveformColorSchemes.sunset;

      case WaveformPattern.edmDrop:
      case WaveformPattern.dubstep:
      case WaveformPattern.techno:
      case WaveformPattern.houseMusic:
        return WaveformColorSchemes.visualizer;

      case WaveformPattern.synthwave:
      case WaveformPattern.retrowave:
      case WaveformPattern.vaporwave:
        return WaveformColorSchemes.neon;

      case WaveformPattern.gaming:
      case WaveformPattern.digitalGlitch:
        return WaveformColorSchemes.neon;

      case WaveformPattern.whiteNoise:
      case WaveformPattern.pinkNoise:
        return WaveformColorSchemes.monochrome;

      default:
        return WaveformColorSchemes.classic;
    }
  }

  /// Generates fake waveform for URL-based audio files
  static WaveformData generateFakeWaveformForUrl({
    required String url,
    required WaveformPattern pattern,
    int durationMs = 30000,
    int samplesPerSecond = 100,
    double frequency = defaultFrequency,
    int sampleRate = defaultSampleRate,
    int channels = defaultChannels,
    required int estimatedDurationMs,
  }) {
    return generateFakeWaveform(
      pattern: pattern,
      durationMs: durationMs,
      samplesPerSecond: samplesPerSecond,
      frequency: frequency,
      sampleRate: sampleRate,
      channels: channels,
    );
  }

  // Helper methods for patterns without separate files
  static double _generateDigitalGlitch(
    double t,
    double frequency,
    Random random,
  ) {
    if (random.nextDouble() > 0.9) {
      return random.nextDouble();
    }
    return 0.5 * sin(2 * pi * frequency * 2 * t / 1000);
  }

  static double _generateWhiteNoise(Random random) {
    return random.nextDouble();
  }

  static double _generateCinematicEpic(
    double t,
    double timeRatio,
    double frequency,
    Random random,
  ) {
    // Build from quiet to epic
    final buildMultiplier = timeRatio * 2;
    final bass = 0.4 * sin(2 * pi * frequency * 0.5 * t / 1000);
    final lead = 0.6 * sin(2 * pi * frequency * 1.5 * t / 1000);
    return (bass.abs() + lead.abs()) * buildMultiplier.clamp(0.0, 1.0);
  }

  static double _generateDeepBass(double t, double frequency) {
    final bassFreq = frequency * 0.25;
    return 0.8 * sin(2 * pi * bassFreq * t / 1000).abs();
  }

  static double _generateHighEnergy(
    double t,
    double timeRatio,
    double frequency,
    Random random,
  ) {
    final kick = (t % 500 < 50) ? 0.9 : 0.0;
    final synth = 0.7 * sin(2 * pi * frequency * 2 * t / 1000);
    final noise = 0.3 * random.nextDouble();
    return (kick + synth.abs() + noise).clamp(0.0, 1.0);
  }
}
