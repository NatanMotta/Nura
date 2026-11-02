/// Represents a specific type of noise detected in audio
class DetectedNoise {
  /// Type of noise detected
  final NoiseType type;

  /// Confidence level of detection (0.0 to 1.0)
  final double confidence;

  /// Start time of noise in milliseconds
  final int startTimeMs;

  /// End time of noise in milliseconds
  final int endTimeMs;

  /// Peak amplitude of the noise (0.0 to 1.0)
  final double peakAmplitude;

  /// Average amplitude of the noise (0.0 to 1.0)
  final double averageAmplitude;

  /// Frequency range where noise is most prominent
  final FrequencyRange frequencyRange;

  /// Additional metadata specific to the noise type
  final Map<String, dynamic>? metadata;

  /// Creates a detected noise instance
  const DetectedNoise({
    required this.type,
    required this.confidence,
    required this.startTimeMs,
    required this.endTimeMs,
    required this.peakAmplitude,
    required this.averageAmplitude,
    required this.frequencyRange,
    this.metadata,
  });

  /// Creates from map data
  factory DetectedNoise.fromMap(Map<String, dynamic> map) {
    return DetectedNoise(
      type: NoiseType.values[map['type'] as int],
      confidence: (map['confidence'] as num).toDouble(),
      startTimeMs: map['startTimeMs'] as int,
      endTimeMs: map['endTimeMs'] as int,
      peakAmplitude: (map['peakAmplitude'] as num).toDouble(),
      averageAmplitude: (map['averageAmplitude'] as num).toDouble(),
      frequencyRange: FrequencyRange.fromMap(
        map['frequencyRange'] as Map<String, dynamic>,
      ),
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Converts to map for platform communication
  Map<String, dynamic> toMap() {
    return {
      'type': type.index,
      'confidence': confidence,
      'startTimeMs': startTimeMs,
      'endTimeMs': endTimeMs,
      'peakAmplitude': peakAmplitude,
      'averageAmplitude': averageAmplitude,
      'frequencyRange': frequencyRange.toMap(),
      'metadata': metadata,
    };
  }

  /// Duration of the noise in milliseconds
  int get durationMs => endTimeMs - startTimeMs;

  /// Duration of the noise in seconds
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

  @override
  String toString() {
    return 'DetectedNoise(${type.description}, confidence: ${(confidence * 100).toStringAsFixed(1)}%, '
        'duration: ${durationSeconds.toStringAsFixed(1)}s)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DetectedNoise &&
        other.type == type &&
        other.startTimeMs == startTimeMs &&
        other.endTimeMs == endTimeMs;
  }

  @override
  int get hashCode => Object.hash(type, startTimeMs, endTimeMs);
}

/// Types of background noise that can be detected
enum NoiseType {
  /// Traffic noise (cars, trucks, motorcycles)
  traffic,

  /// Car horn sounds
  carHorn,

  /// Dog barking
  dogBarking,

  /// Bird sounds
  birds,

  /// Wind noise
  wind,

  /// Rain or water sounds
  rain,

  /// Air conditioning or HVAC noise
  hvac,

  /// Electrical hum (50/60Hz and harmonics)
  electricalHum,

  /// Computer fan noise
  fanNoise,

  /// Construction or machinery noise
  construction,

  /// Aircraft noise
  aircraft,

  /// Children playing or talking
  children,

  /// Adult conversation in background
  conversation,

  /// Music playing in background
  backgroundMusic,

  /// Television or radio in background
  mediaPlayback,

  /// Phone ringing or notification sounds
  phoneRinging,

  /// Keyboard typing sounds
  typing,

  /// Paper rustling or handling
  paperRustling,

  /// Footsteps
  footsteps,

  /// Door opening/closing or knocking
  door,

  /// Microphone handling noise
  micHandling,

  /// Mouth sounds (lip smacks, breathing)
  mouthSounds,

  /// Clothing or fabric rustling
  clothingRustle,

  /// Unknown or unclassified noise
  unknown;

  /// Human-readable description
  String get description {
    switch (this) {
      case NoiseType.traffic:
        return 'Traffic Noise';
      case NoiseType.carHorn:
        return 'Car Horn';
      case NoiseType.dogBarking:
        return 'Dog Barking';
      case NoiseType.birds:
        return 'Bird Sounds';
      case NoiseType.wind:
        return 'Wind Noise';
      case NoiseType.rain:
        return 'Rain/Water Sounds';
      case NoiseType.hvac:
        return 'HVAC/Air Conditioning';
      case NoiseType.electricalHum:
        return 'Electrical Hum';
      case NoiseType.fanNoise:
        return 'Fan Noise';
      case NoiseType.construction:
        return 'Construction/Machinery';
      case NoiseType.aircraft:
        return 'Aircraft';
      case NoiseType.children:
        return 'Children';
      case NoiseType.conversation:
        return 'Background Conversation';
      case NoiseType.backgroundMusic:
        return 'Background Music';
      case NoiseType.mediaPlayback:
        return 'TV/Radio';
      case NoiseType.phoneRinging:
        return 'Phone/Notifications';
      case NoiseType.typing:
        return 'Keyboard Typing';
      case NoiseType.paperRustling:
        return 'Paper Handling';
      case NoiseType.footsteps:
        return 'Footsteps';
      case NoiseType.door:
        return 'Door Sounds';
      case NoiseType.micHandling:
        return 'Microphone Handling';
      case NoiseType.mouthSounds:
        return 'Mouth Sounds';
      case NoiseType.clothingRustle:
        return 'Clothing Rustle';
      case NoiseType.unknown:
        return 'Unknown Noise';
    }
  }

  /// Category for grouping similar noise types
  NoiseCategory get category {
    switch (this) {
      case NoiseType.traffic:
      case NoiseType.carHorn:
      case NoiseType.aircraft:
      case NoiseType.construction:
        return NoiseCategory.environmental;

      case NoiseType.dogBarking:
      case NoiseType.birds:
      case NoiseType.children:
      case NoiseType.conversation:
        return NoiseCategory.vocal;

      case NoiseType.wind:
      case NoiseType.rain:
        return NoiseCategory.natural;

      case NoiseType.hvac:
      case NoiseType.electricalHum:
      case NoiseType.fanNoise:
        return NoiseCategory.mechanical;

      case NoiseType.backgroundMusic:
      case NoiseType.mediaPlayback:
        return NoiseCategory.media;

      case NoiseType.phoneRinging:
      case NoiseType.typing:
      case NoiseType.paperRustling:
      case NoiseType.footsteps:
      case NoiseType.door:
        return NoiseCategory.activity;

      case NoiseType.micHandling:
      case NoiseType.mouthSounds:
      case NoiseType.clothingRustle:
        return NoiseCategory.recording;

      case NoiseType.unknown:
        return NoiseCategory.unknown;
    }
  }

  /// Typical frequency range for this noise type
  FrequencyRange get typicalFrequencyRange {
    switch (this) {
      case NoiseType.electricalHum:
        return const FrequencyRange(
          lowHz: 50,
          highHz: 180,
        ); // 50/60Hz and harmonics
      case NoiseType.traffic:
        return const FrequencyRange(lowHz: 80, highHz: 800);
      case NoiseType.carHorn:
        return const FrequencyRange(lowHz: 400, highHz: 1200);
      case NoiseType.dogBarking:
        return const FrequencyRange(lowHz: 300, highHz: 2000);
      case NoiseType.birds:
        return const FrequencyRange(lowHz: 1000, highHz: 8000);
      case NoiseType.wind:
        return const FrequencyRange(lowHz: 20, highHz: 500);
      case NoiseType.hvac:
        return const FrequencyRange(lowHz: 100, highHz: 1000);
      case NoiseType.conversation:
        return const FrequencyRange(lowHz: 200, highHz: 4000);
      case NoiseType.typing:
        return const FrequencyRange(lowHz: 1000, highHz: 5000);
      default:
        return const FrequencyRange(lowHz: 20, highHz: 20000); // Full range
    }
  }
}

/// Categories for grouping noise types
enum NoiseCategory {
  environmental,
  vocal,
  natural,
  mechanical,
  media,
  activity,
  recording,
  unknown;

  String get description {
    switch (this) {
      case NoiseCategory.environmental:
        return 'Environmental';
      case NoiseCategory.vocal:
        return 'Vocal/Animal';
      case NoiseCategory.natural:
        return 'Natural';
      case NoiseCategory.mechanical:
        return 'Mechanical';
      case NoiseCategory.media:
        return 'Media';
      case NoiseCategory.activity:
        return 'Activity';
      case NoiseCategory.recording:
        return 'Recording Issues';
      case NoiseCategory.unknown:
        return 'Unknown';
    }
  }
}

/// Represents a frequency range
class FrequencyRange {
  /// Low frequency bound in Hz
  final double lowHz;

  /// High frequency bound in Hz
  final double highHz;

  /// Creates a frequency range
  const FrequencyRange({required this.lowHz, required this.highHz});

  /// Creates from map data
  factory FrequencyRange.fromMap(Map<String, dynamic> map) {
    return FrequencyRange(
      lowHz: (map['lowHz'] as num).toDouble(),
      highHz: (map['highHz'] as num).toDouble(),
    );
  }

  /// Converts to map
  Map<String, dynamic> toMap() {
    return {'lowHz': lowHz, 'highHz': highHz};
  }

  /// Bandwidth in Hz
  double get bandwidth => highHz - lowHz;

  /// Center frequency in Hz
  double get centerHz => (lowHz + highHz) / 2;

  /// Formatted frequency range string
  String get formatted {
    if (lowHz <= 1000 && highHz <= 1000) {
      return '${lowHz.toStringAsFixed(0)}-${highHz.toStringAsFixed(0)} Hz';
    } else if (lowHz > 1000 && highHz > 1000) {
      return '${(lowHz / 1000).toStringAsFixed(1)}-${(highHz / 1000).toStringAsFixed(1)} kHz';
    } else {
      return '${lowHz.toStringAsFixed(0)} Hz - ${(highHz / 1000).toStringAsFixed(1)} kHz';
    }
  }

  @override
  String toString() => 'FrequencyRange($formatted)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FrequencyRange &&
        other.lowHz == lowHz &&
        other.highHz == highHz;
  }

  @override
  int get hashCode => Object.hash(lowHz, highHz);
}
