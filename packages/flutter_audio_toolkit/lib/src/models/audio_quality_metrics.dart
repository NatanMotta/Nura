import 'package:flutter_audio_toolkit/flutter_audio_toolkit.dart';

/// Comprehensive audio quality metrics
class AudioQualityMetrics {
  /// Peak level in dBFS (decibels relative to full scale)
  final double peakDbFS;

  /// Average (RMS) level in dBFS
  final double averageDbFS;

  /// Dynamic range in dB (difference between peak and average)
  final double dynamicRange;

  /// Signal-to-noise ratio in dB
  final double signalToNoiseRatio;

  /// Percentage of samples that are clipped (0-100)
  final double clippingPercentage;

  /// Total harmonic distortion percentage (0-100)
  final double totalHarmonicDistortion;

  /// Stereo balance (-1.0 to 1.0, 0 = centered)
  final double stereoBalance;

  /// Overall quality score (0.0 to 1.0)
  final double overallScore;

  /// Loudness units relative to full scale (LUFS)
  final double lufs;

  /// Crest factor (peak to RMS ratio)
  final double crestFactor;

  /// Zero crossing rate (indicator of noisiness)
  final double zeroCrossingRate;

  /// Spectral centroid (brightness indicator) in Hz
  final double spectralCentroid;

  /// Spectral rolloff frequency in Hz
  final double spectralRolloff;

  /// Creates audio quality metrics
  const AudioQualityMetrics({
    required this.peakDbFS,
    required this.averageDbFS,
    required this.dynamicRange,
    required this.signalToNoiseRatio,
    required this.clippingPercentage,
    required this.totalHarmonicDistortion,
    required this.stereoBalance,
    required this.overallScore,
    required this.lufs,
    required this.crestFactor,
    required this.zeroCrossingRate,
    required this.spectralCentroid,
    required this.spectralRolloff,
  });

  /// Creates from map data
  factory AudioQualityMetrics.fromMap(Map<String, dynamic> map) {
    return AudioQualityMetrics(
      peakDbFS: (map['peakDbFS'] as num).toDouble(),
      averageDbFS: (map['averageDbFS'] as num).toDouble(),
      dynamicRange: (map['dynamicRange'] as num).toDouble(),
      signalToNoiseRatio: (map['signalToNoiseRatio'] as num).toDouble(),
      clippingPercentage: (map['clippingPercentage'] as num).toDouble(),
      totalHarmonicDistortion:
          (map['totalHarmonicDistortion'] as num).toDouble(),
      stereoBalance: (map['stereoBalance'] as num).toDouble(),
      overallScore: (map['overallScore'] as num).toDouble(),
      lufs: (map['lufs'] as num).toDouble(),
      crestFactor: (map['crestFactor'] as num).toDouble(),
      zeroCrossingRate: (map['zeroCrossingRate'] as num).toDouble(),
      spectralCentroid: (map['spectralCentroid'] as num).toDouble(),
      spectralRolloff: (map['spectralRolloff'] as num).toDouble(),
    );
  }

  /// Converts to map
  Map<String, dynamic> toMap() {
    return {
      'peakDbFS': peakDbFS,
      'averageDbFS': averageDbFS,
      'dynamicRange': dynamicRange,
      'signalToNoiseRatio': signalToNoiseRatio,
      'clippingPercentage': clippingPercentage,
      'totalHarmonicDistortion': totalHarmonicDistortion,
      'stereoBalance': stereoBalance,
      'overallScore': overallScore,
      'lufs': lufs,
      'crestFactor': crestFactor,
      'zeroCrossingRate': zeroCrossingRate,
      'spectralCentroid': spectralCentroid,
      'spectralRolloff': spectralRolloff,
    };
  }

  /// Gets quality grade based on overall score
  AudioQualityGrade get grade {
    if (overallScore >= 0.9) return AudioQualityGrade.excellent;
    if (overallScore >= 0.8) return AudioQualityGrade.good;
    if (overallScore >= 0.6) return AudioQualityGrade.fair;
    if (overallScore >= 0.4) return AudioQualityGrade.poor;
    return AudioQualityGrade.veryPoor;
  }

  /// Gets loudness category
  LoudnessCategory get loudnessCategory {
    if (lufs > -6) return LoudnessCategory.tooLoud;
    if (lufs >= -14) return LoudnessCategory.loud;
    if (lufs >= -23) return LoudnessCategory.optimal;
    if (lufs >= -35) return LoudnessCategory.quiet;
    return LoudnessCategory.tooQuiet;
  }

  /// Checks if audio has clipping issues
  bool get hasClipping => clippingPercentage > 0.1;

  /// Checks if audio has distortion issues
  bool get hasDistortion => totalHarmonicDistortion > 5.0;

  /// Checks if audio has balance issues
  bool get hasBalanceIssues => stereoBalance.abs() > 0.3;

  /// Checks if audio is too bright (high spectral centroid)
  bool get isTooRight => spectralCentroid > 3000;

  /// Checks if audio is too dull (low spectral centroid)
  bool get isTooDull => spectralCentroid < 1000;

  /// Gets formatted peak level string
  String get peakLevelFormatted => '${peakDbFS.toStringAsFixed(1)} dBFS';

  /// Gets formatted average level string
  String get averageLevelFormatted => '${averageDbFS.toStringAsFixed(1)} dBFS';

  /// Gets formatted SNR string
  String get snrFormatted => '${signalToNoiseRatio.toStringAsFixed(1)} dB';

  /// Gets formatted LUFS string
  String get lufsFormatted => '${lufs.toStringAsFixed(1)} LUFS';

  @override
  String toString() {
    return 'AudioQualityMetrics(grade: $grade, peak: $peakLevelFormatted, '
        'SNR: $snrFormatted, score: ${(overallScore * 100).toStringAsFixed(1)}%)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AudioQualityMetrics &&
        other.overallScore == overallScore &&
        other.peakDbFS == peakDbFS &&
        other.signalToNoiseRatio == signalToNoiseRatio;
  }

  @override
  int get hashCode => Object.hash(overallScore, peakDbFS, signalToNoiseRatio);
}

/// Audio quality grades
enum AudioQualityGrade {
  excellent,
  good,
  fair,
  poor,
  veryPoor;

  String get description {
    switch (this) {
      case AudioQualityGrade.excellent:
        return 'Excellent';
      case AudioQualityGrade.good:
        return 'Good';
      case AudioQualityGrade.fair:
        return 'Fair';
      case AudioQualityGrade.poor:
        return 'Poor';
      case AudioQualityGrade.veryPoor:
        return 'Very Poor';
    }
  }

  int get score {
    switch (this) {
      case AudioQualityGrade.excellent:
        return 95;
      case AudioQualityGrade.good:
        return 80;
      case AudioQualityGrade.fair:
        return 60;
      case AudioQualityGrade.poor:
        return 40;
      case AudioQualityGrade.veryPoor:
        return 20;
    }
  }
}

/// Loudness categories based on LUFS measurements
enum LoudnessCategory {
  tooLoud,
  loud,
  optimal,
  quiet,
  tooQuiet;

  String get description {
    switch (this) {
      case LoudnessCategory.tooLoud:
        return 'Too Loud';
      case LoudnessCategory.loud:
        return 'Loud';
      case LoudnessCategory.optimal:
        return 'Optimal';
      case LoudnessCategory.quiet:
        return 'Quiet';
      case LoudnessCategory.tooQuiet:
        return 'Too Quiet';
    }
  }
}

/// Frequency analysis data
class FrequencyAnalysis {
  /// Frequency spectrum data (frequency bins and their magnitudes)
  final List<FrequencyBin> spectrum;

  /// Dominant frequency in Hz
  final double dominantFrequency;

  /// Fundamental frequency in Hz (for pitched audio)
  final double? fundamentalFrequency;

  /// Low frequency energy (20-250 Hz) as percentage of total
  final double lowFrequencyEnergy;

  /// Mid frequency energy (250-4000 Hz) as percentage of total
  final double midFrequencyEnergy;

  /// High frequency energy (4000-20000 Hz) as percentage of total
  final double highFrequencyEnergy;

  /// Spectral flatness measure (0-1, higher = more noise-like)
  final double spectralFlatness;

  /// Spectral slope (dB/octave)
  final double spectralSlope;

  /// Whether low-frequency rumble is detected
  final bool hasLowFrequencyRumble;

  /// Whether high-frequency hiss is detected
  final bool hasHighFrequencyHiss;

  /// Frequency bands with excessive energy
  final List<ProblematicFrequencyBand> problematicBands;

  /// Creates frequency analysis data
  const FrequencyAnalysis({
    required this.spectrum,
    required this.dominantFrequency,
    this.fundamentalFrequency,
    required this.lowFrequencyEnergy,
    required this.midFrequencyEnergy,
    required this.highFrequencyEnergy,
    required this.spectralFlatness,
    required this.spectralSlope,
    required this.hasLowFrequencyRumble,
    required this.hasHighFrequencyHiss,
    required this.problematicBands,
  });

  /// Creates from map data
  factory FrequencyAnalysis.fromMap(Map<String, dynamic> map) {
    return FrequencyAnalysis(
      spectrum:
          (map['spectrum'] as List)
              .map((e) => FrequencyBin.fromMap(e as Map<String, dynamic>))
              .toList(),
      dominantFrequency: (map['dominantFrequency'] as num).toDouble(),
      fundamentalFrequency:
          map['fundamentalFrequency'] != null
              ? (map['fundamentalFrequency'] as num).toDouble()
              : null,
      lowFrequencyEnergy: (map['lowFrequencyEnergy'] as num).toDouble(),
      midFrequencyEnergy: (map['midFrequencyEnergy'] as num).toDouble(),
      highFrequencyEnergy: (map['highFrequencyEnergy'] as num).toDouble(),
      spectralFlatness: (map['spectralFlatness'] as num).toDouble(),
      spectralSlope: (map['spectralSlope'] as num).toDouble(),
      hasLowFrequencyRumble: map['hasLowFrequencyRumble'] as bool,
      hasHighFrequencyHiss: map['hasHighFrequencyHiss'] as bool,
      problematicBands:
          (map['problematicBands'] as List)
              .map(
                (e) =>
                    ProblematicFrequencyBand.fromMap(e as Map<String, dynamic>),
              )
              .toList(),
    );
  }

  /// Converts to map
  Map<String, dynamic> toMap() {
    return {
      'spectrum': spectrum.map((e) => e.toMap()).toList(),
      'dominantFrequency': dominantFrequency,
      'fundamentalFrequency': fundamentalFrequency,
      'lowFrequencyEnergy': lowFrequencyEnergy,
      'midFrequencyEnergy': midFrequencyEnergy,
      'highFrequencyEnergy': highFrequencyEnergy,
      'spectralFlatness': spectralFlatness,
      'spectralSlope': spectralSlope,
      'hasLowFrequencyRumble': hasLowFrequencyRumble,
      'hasHighFrequencyHiss': hasHighFrequencyHiss,
      'problematicBands': problematicBands.map((e) => e.toMap()).toList(),
    };
  }

  /// Gets frequency distribution description
  String get frequencyDistribution {
    if (lowFrequencyEnergy > 50) return 'Bass Heavy';
    if (highFrequencyEnergy > 40) return 'Treble Heavy';
    if (midFrequencyEnergy >= 60) return 'Mid-Range Heavy';
    return 'Balanced';
  }

  /// Gets tonal characteristics
  List<String> get tonalCharacteristics {
    final characteristics = <String>[];

    if (hasLowFrequencyRumble) {
      characteristics.add('Low-frequency rumble');
    }

    if (hasHighFrequencyHiss) {
      characteristics.add('High-frequency hiss');
    }

    if (spectralFlatness > 0.8) {
      characteristics.add('Noise-like content');
    } else if (spectralFlatness < 0.2) {
      characteristics.add('Tonal content');
    }

    if (spectralSlope < -6) {
      characteristics.add('Bright sound');
    } else if (spectralSlope > -3) {
      characteristics.add('Dull sound');
    }

    return characteristics;
  }

  @override
  String toString() {
    return 'FrequencyAnalysis(dominant: ${dominantFrequency.toStringAsFixed(1)} Hz, '
        'distribution: $frequencyDistribution)';
  }
}

/// Represents a frequency bin in the spectrum
class FrequencyBin {
  /// Center frequency of the bin in Hz
  final double frequencyHz;

  /// Magnitude/energy of this frequency bin
  final double magnitude;

  /// Phase of this frequency bin in radians
  final double phase;

  /// Creates a frequency bin
  const FrequencyBin({
    required this.frequencyHz,
    required this.magnitude,
    required this.phase,
  });

  /// Creates from map data
  factory FrequencyBin.fromMap(Map<String, dynamic> map) {
    return FrequencyBin(
      frequencyHz: (map['frequencyHz'] as num).toDouble(),
      magnitude: (map['magnitude'] as num).toDouble(),
      phase: (map['phase'] as num).toDouble(),
    );
  }

  /// Converts to map
  Map<String, dynamic> toMap() {
    return {'frequencyHz': frequencyHz, 'magnitude': magnitude, 'phase': phase};
  }
}

/// Represents a problematic frequency band
class ProblematicFrequencyBand {
  /// Frequency range of the problem
  final FrequencyRange range;

  /// Type of problem detected
  final FrequencyProblemType problemType;

  /// Severity of the problem (0.0 to 1.0)
  final double severity;

  /// Suggested action to address the problem
  final String suggestedAction;

  /// Creates a problematic frequency band
  const ProblematicFrequencyBand({
    required this.range,
    required this.problemType,
    required this.severity,
    required this.suggestedAction,
  });

  /// Creates from map data
  factory ProblematicFrequencyBand.fromMap(Map<String, dynamic> map) {
    return ProblematicFrequencyBand(
      range: FrequencyRange.fromMap(map['range'] as Map<String, dynamic>),
      problemType: FrequencyProblemType.values[map['problemType'] as int],
      severity: (map['severity'] as num).toDouble(),
      suggestedAction: map['suggestedAction'] as String,
    );
  }

  /// Converts to map
  Map<String, dynamic> toMap() {
    return {
      'range': range.toMap(),
      'problemType': problemType.index,
      'severity': severity,
      'suggestedAction': suggestedAction,
    };
  }

  @override
  String toString() {
    return 'ProblematicBand(${range.formatted}, ${problemType.description}, '
        'severity: ${(severity * 100).toStringAsFixed(1)}%)';
  }
}

/// Types of frequency problems
enum FrequencyProblemType {
  excessiveEnergy,
  resonance,
  notch,
  hum,
  rumble,
  hiss;

  String get description {
    switch (this) {
      case FrequencyProblemType.excessiveEnergy:
        return 'Excessive Energy';
      case FrequencyProblemType.resonance:
        return 'Resonance';
      case FrequencyProblemType.notch:
        return 'Frequency Notch';
      case FrequencyProblemType.hum:
        return 'Electrical Hum';
      case FrequencyProblemType.rumble:
        return 'Low-Frequency Rumble';
      case FrequencyProblemType.hiss:
        return 'High-Frequency Hiss';
    }
  }
}
