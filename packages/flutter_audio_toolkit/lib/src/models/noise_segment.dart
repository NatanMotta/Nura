import 'package:flutter_audio_toolkit/flutter_audio_toolkit.dart';

/// Represents a time segment of audio with noise analysis
class NoiseSegment {
  /// Start time of the segment in milliseconds
  final int startTimeMs;

  /// End time of the segment in milliseconds
  final int endTimeMs;

  /// Noise level for this segment
  final NoiseLevel noiseLevel;

  /// Volume level for this segment
  final VolumeLevel volumeLevel;

  /// Detected noises in this segment
  final List<DetectedNoise> detectedNoises;

  /// Peak amplitude in this segment (0.0 to 1.0)
  final double peakAmplitude;

  /// Average amplitude in this segment (0.0 to 1.0)
  final double averageAmplitude;

  /// Signal-to-noise ratio for this segment in dB
  final double snrDb;

  /// Spectral characteristics of this segment
  final SegmentSpectralData spectralData;

  /// Creates a noise segment
  const NoiseSegment({
    required this.startTimeMs,
    required this.endTimeMs,
    required this.noiseLevel,
    required this.volumeLevel,
    required this.detectedNoises,
    required this.peakAmplitude,
    required this.averageAmplitude,
    required this.snrDb,
    required this.spectralData,
  });

  /// Creates from map data
  factory NoiseSegment.fromMap(Map<String, dynamic> map) {
    return NoiseSegment(
      startTimeMs: map['startTimeMs'] as int,
      endTimeMs: map['endTimeMs'] as int,
      noiseLevel: NoiseLevel.values[map['noiseLevel'] as int],
      volumeLevel: VolumeLevel.values[map['volumeLevel'] as int],
      detectedNoises:
          (map['detectedNoises'] as List)
              .map((e) => DetectedNoise.fromMap(e as Map<String, dynamic>))
              .toList(),
      peakAmplitude: (map['peakAmplitude'] as num).toDouble(),
      averageAmplitude: (map['averageAmplitude'] as num).toDouble(),
      snrDb: (map['snrDb'] as num).toDouble(),
      spectralData: SegmentSpectralData.fromMap(
        map['spectralData'] as Map<String, dynamic>,
      ),
    );
  }

  /// Converts to map
  Map<String, dynamic> toMap() {
    return {
      'startTimeMs': startTimeMs,
      'endTimeMs': endTimeMs,
      'noiseLevel': noiseLevel.index,
      'volumeLevel': volumeLevel.index,
      'detectedNoises': detectedNoises.map((e) => e.toMap()).toList(),
      'peakAmplitude': peakAmplitude,
      'averageAmplitude': averageAmplitude,
      'snrDb': snrDb,
      'spectralData': spectralData.toMap(),
    };
  }

  /// Duration of the segment in milliseconds
  int get durationMs => endTimeMs - startTimeMs;

  /// Duration of the segment in seconds
  double get durationSeconds => durationMs / 1000.0;

  /// Formatted time range string
  String get timeRange {
    final start = Duration(milliseconds: startTimeMs);
    final end = Duration(milliseconds: endTimeMs);
    return '${_formatDuration(start)} - ${_formatDuration(end)}';
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    final milliseconds = duration.inMilliseconds % 1000;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}.'
        '${(milliseconds ~/ 10).toString().padLeft(2, '0')}';
  }

  /// Gets the most problematic noise in this segment
  DetectedNoise? get mostProblematicNoise {
    if (detectedNoises.isEmpty) return null;

    return detectedNoises.reduce((a, b) {
      final aScore = a.confidence * a.averageAmplitude;
      final bScore = b.confidence * b.averageAmplitude;
      return aScore > bScore ? a : b;
    });
  }

  /// Checks if this segment has any issues
  bool get hasIssues {
    return noiseLevel == NoiseLevel.high ||
        noiseLevel == NoiseLevel.veryHigh ||
        volumeLevel == VolumeLevel.tooLoud ||
        volumeLevel == VolumeLevel.tooQuiet ||
        detectedNoises.any((n) => n.confidence > 0.7);
  }

  /// Gets quality score for this segment (0.0 to 1.0)
  double get qualityScore {
    double score = 1.0;

    // Penalize for noise level
    switch (noiseLevel) {
      case NoiseLevel.veryLow:
        score *= 1.0;
        break;
      case NoiseLevel.low:
        score *= 0.9;
        break;
      case NoiseLevel.medium:
        score *= 0.7;
        break;
      case NoiseLevel.high:
        score *= 0.4;
        break;
      case NoiseLevel.veryHigh:
        score *= 0.2;
        break;
    }

    // Penalize for volume issues
    switch (volumeLevel) {
      case VolumeLevel.optimal:
        score *= 1.0;
        break;
      case VolumeLevel.loud:
        score *= 0.9;
        break;
      case VolumeLevel.tooQuiet:
      case VolumeLevel.tooLoud:
        score *= 0.6;
        break;
    }

    // Penalize for detected noises
    for (final noise in detectedNoises) {
      score *= (1.0 - noise.confidence * 0.3);
    }

    return score.clamp(0.0, 1.0);
  }

  @override
  String toString() {
    return 'NoiseSegment($timeRange, noise: $noiseLevel, volume: $volumeLevel, '
        'detections: ${detectedNoises.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NoiseSegment &&
        other.startTimeMs == startTimeMs &&
        other.endTimeMs == endTimeMs;
  }

  @override
  int get hashCode => Object.hash(startTimeMs, endTimeMs);
}

/// Spectral characteristics for a segment
class SegmentSpectralData {
  /// Dominant frequency in this segment
  final double dominantFrequency;

  /// Spectral centroid (brightness measure) in Hz
  final double spectralCentroid;

  /// Spectral bandwidth in Hz
  final double spectralBandwidth;

  /// Spectral rolloff frequency in Hz
  final double spectralRolloff;

  /// Zero crossing rate (measure of noisiness)
  final double zeroCrossingRate;

  /// Mel-frequency cepstral coefficients for this segment
  final List<double> mfcc;

  /// Creates segment spectral data
  const SegmentSpectralData({
    required this.dominantFrequency,
    required this.spectralCentroid,
    required this.spectralBandwidth,
    required this.spectralRolloff,
    required this.zeroCrossingRate,
    required this.mfcc,
  });

  /// Creates from map data
  factory SegmentSpectralData.fromMap(Map<String, dynamic> map) {
    return SegmentSpectralData(
      dominantFrequency: (map['dominantFrequency'] as num).toDouble(),
      spectralCentroid: (map['spectralCentroid'] as num).toDouble(),
      spectralBandwidth: (map['spectralBandwidth'] as num).toDouble(),
      spectralRolloff: (map['spectralRolloff'] as num).toDouble(),
      zeroCrossingRate: (map['zeroCrossingRate'] as num).toDouble(),
      mfcc: (map['mfcc'] as List).map((e) => (e as num).toDouble()).toList(),
    );
  }

  /// Converts to map
  Map<String, dynamic> toMap() {
    return {
      'dominantFrequency': dominantFrequency,
      'spectralCentroid': spectralCentroid,
      'spectralBandwidth': spectralBandwidth,
      'spectralRolloff': spectralRolloff,
      'zeroCrossingRate': zeroCrossingRate,
      'mfcc': mfcc,
    };
  }

  /// Gets perceptual brightness (0.0 to 1.0)
  double get brightness {
    // Normalize spectral centroid to brightness scale
    return (spectralCentroid / 4000.0).clamp(0.0, 1.0);
  }

  /// Gets tonal vs noise characteristics (0.0 = pure noise, 1.0 = pure tone)
  double get tonality {
    // Based on zero crossing rate - lower rate indicates more tonal content
    return (1.0 - (zeroCrossingRate / 0.5)).clamp(0.0, 1.0);
  }

  @override
  String toString() {
    return 'SegmentSpectralData(dominant: ${dominantFrequency.toStringAsFixed(1)} Hz, '
        'centroid: ${spectralCentroid.toStringAsFixed(1)} Hz, '
        'brightness: ${(brightness * 100).toStringAsFixed(1)}%)';
  }
}
