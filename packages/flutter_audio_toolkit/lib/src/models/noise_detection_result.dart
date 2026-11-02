import 'package:flutter_audio_toolkit/flutter_audio_toolkit.dart';

/// Result of noise detection analysis on an audio file
class NoiseDetectionResult {
  /// Overall noise level assessment
  final NoiseLevel overallNoiseLevel;

  /// Volume level assessment
  final VolumeLevel volumeLevel;

  /// List of detected background noises
  final List<DetectedNoise> detectedNoises;

  /// Audio quality metrics
  final AudioQualityMetrics qualityMetrics;

  /// Frequency analysis data
  final FrequencyAnalysis frequencyAnalysis;

  /// Time-based analysis segments
  final List<NoiseSegment> segments;

  /// Overall confidence score (0.0 to 1.0)
  final double confidenceScore;

  /// Timestamp when analysis was performed
  final DateTime analysisTimestamp;

  /// Duration of analyzed audio in milliseconds
  final int analyzedDurationMs;

  /// Creates a noise detection result
  const NoiseDetectionResult({
    required this.overallNoiseLevel,
    required this.volumeLevel,
    required this.detectedNoises,
    required this.qualityMetrics,
    required this.frequencyAnalysis,
    required this.segments,
    required this.confidenceScore,
    required this.analysisTimestamp,
    required this.analyzedDurationMs,
  });

  /// Creates a result from analysis data map
  factory NoiseDetectionResult.fromMap(Map<String, dynamic> map) {
    return NoiseDetectionResult(
      overallNoiseLevel: NoiseLevel.values[map['overallNoiseLevel'] as int],
      volumeLevel: VolumeLevel.values[map['volumeLevel'] as int],
      detectedNoises:
          (map['detectedNoises'] as List)
              .map((e) => DetectedNoise.fromMap(e as Map<String, dynamic>))
              .toList(),
      qualityMetrics: AudioQualityMetrics.fromMap(
        map['qualityMetrics'] as Map<String, dynamic>,
      ),
      frequencyAnalysis: FrequencyAnalysis.fromMap(
        map['frequencyAnalysis'] as Map<String, dynamic>,
      ),
      segments:
          (map['segments'] as List)
              .map((e) => NoiseSegment.fromMap(e as Map<String, dynamic>))
              .toList(),
      confidenceScore: (map['confidenceScore'] as num).toDouble(),
      analysisTimestamp: DateTime.parse(map['analysisTimestamp'] as String),
      analyzedDurationMs: map['analyzedDurationMs'] as int,
    );
  }

  /// Converts result to map for platform communication
  Map<String, dynamic> toMap() {
    return {
      'overallNoiseLevel': overallNoiseLevel.index,
      'volumeLevel': volumeLevel.index,
      'detectedNoises': detectedNoises.map((e) => e.toMap()).toList(),
      'qualityMetrics': qualityMetrics.toMap(),
      'frequencyAnalysis': frequencyAnalysis.toMap(),
      'segments': segments.map((e) => e.toMap()).toList(),
      'confidenceScore': confidenceScore,
      'analysisTimestamp': analysisTimestamp.toIso8601String(),
      'analyzedDurationMs': analyzedDurationMs,
    };
  }

  /// Gets a human-readable summary of the analysis
  String get summary {
    final buffer = StringBuffer();
    buffer.writeln('Audio Analysis Summary:');
    buffer.writeln('- Overall Noise: ${overallNoiseLevel.description}');
    buffer.writeln('- Volume Level: ${volumeLevel.description}');
    buffer.writeln(
      '- Quality Score: ${(qualityMetrics.overallScore * 100).toStringAsFixed(1)}%',
    );

    if (detectedNoises.isNotEmpty) {
      buffer.writeln('- Detected Noises:');
      for (final noise in detectedNoises) {
        buffer.writeln(
          '  * ${noise.type.description} (${(noise.confidence * 100).toStringAsFixed(1)}% confidence)',
        );
      }
    }

    return buffer.toString();
  }

  /// Gets issues found in the audio
  List<String> get issues {
    final issues = <String>[];

    if (volumeLevel == VolumeLevel.tooLoud) {
      issues.add(
        'Audio is too loud (${qualityMetrics.peakDbFS.toStringAsFixed(1)} dBFS)',
      );
    } else if (volumeLevel == VolumeLevel.tooQuiet) {
      issues.add(
        'Audio is too quiet (${qualityMetrics.averageDbFS.toStringAsFixed(1)} dBFS)',
      );
    }

    if (overallNoiseLevel == NoiseLevel.high) {
      issues.add('High background noise levels detected');
    }

    if (qualityMetrics.dynamicRange < 10) {
      issues.add(
        'Poor dynamic range (${qualityMetrics.dynamicRange.toStringAsFixed(1)} dB)',
      );
    }

    if (qualityMetrics.clippingPercentage > 1.0) {
      issues.add(
        'Audio clipping detected (${qualityMetrics.clippingPercentage.toStringAsFixed(1)}% of samples)',
      );
    }

    for (final noise in detectedNoises.where((n) => n.confidence > 0.7)) {
      issues.add('${noise.type.description} detected');
    }

    return issues;
  }

  /// Gets recommendations for improving audio quality
  List<String> get recommendations {
    final recommendations = <String>[];

    if (volumeLevel == VolumeLevel.tooLoud) {
      recommendations.add('Reduce recording gain or apply compression');
    } else if (volumeLevel == VolumeLevel.tooQuiet) {
      recommendations.add('Increase recording gain or apply normalization');
    }

    if (overallNoiseLevel == NoiseLevel.high) {
      recommendations.add(
        'Use noise reduction or record in quieter environment',
      );
    }

    if (qualityMetrics.clippingPercentage > 0) {
      recommendations.add('Avoid input levels that cause clipping');
    }

    final outdoorNoises = detectedNoises.where(
      (n) =>
          n.type == NoiseType.traffic ||
          n.type == NoiseType.carHorn ||
          n.type == NoiseType.dogBarking ||
          n.type == NoiseType.wind,
    );

    if (outdoorNoises.isNotEmpty) {
      recommendations.add(
        'Consider recording indoors or using directional microphone',
      );
    }

    if (frequencyAnalysis.hasLowFrequencyRumble) {
      recommendations.add(
        'Apply high-pass filter to remove low-frequency rumble',
      );
    }

    return recommendations;
  }

  @override
  String toString() {
    return 'NoiseDetectionResult(level: $overallNoiseLevel, volume: $volumeLevel, '
        'noises: ${detectedNoises.length}, confidence: ${(confidenceScore * 100).toStringAsFixed(1)}%)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NoiseDetectionResult &&
        other.overallNoiseLevel == overallNoiseLevel &&
        other.volumeLevel == volumeLevel &&
        other.confidenceScore == confidenceScore &&
        other.analyzedDurationMs == analyzedDurationMs;
  }

  @override
  int get hashCode {
    return Object.hash(
      overallNoiseLevel,
      volumeLevel,
      confidenceScore,
      analyzedDurationMs,
    );
  }
}

/// Overall noise level in the audio
enum NoiseLevel {
  /// Very clean audio with minimal background noise
  veryLow,

  /// Clean audio with acceptable background noise
  low,

  /// Moderate background noise present
  medium,

  /// High background noise that may affect quality
  high,

  /// Very high background noise that significantly affects quality
  veryHigh;

  /// Human-readable description
  String get description {
    switch (this) {
      case NoiseLevel.veryLow:
        return 'Very Clean';
      case NoiseLevel.low:
        return 'Clean';
      case NoiseLevel.medium:
        return 'Moderate Noise';
      case NoiseLevel.high:
        return 'High Noise';
      case NoiseLevel.veryHigh:
        return 'Very High Noise';
    }
  }

  /// Numeric score (0-100)
  int get score {
    switch (this) {
      case NoiseLevel.veryLow:
        return 95;
      case NoiseLevel.low:
        return 80;
      case NoiseLevel.medium:
        return 60;
      case NoiseLevel.high:
        return 35;
      case NoiseLevel.veryHigh:
        return 10;
    }
  }
}

/// Volume level assessment
enum VolumeLevel {
  /// Audio is too quiet for optimal playback
  tooQuiet,

  /// Audio volume is at optimal level
  optimal,

  /// Audio is slightly loud but acceptable
  loud,

  /// Audio is too loud and may cause distortion
  tooLoud;

  /// Human-readable description
  String get description {
    switch (this) {
      case VolumeLevel.tooQuiet:
        return 'Too Quiet';
      case VolumeLevel.optimal:
        return 'Optimal';
      case VolumeLevel.loud:
        return 'Loud';
      case VolumeLevel.tooLoud:
        return 'Too Loud';
    }
  }
}
