import 'waveform_style.dart';

/// Represents waveform data extracted from an audio file
class WaveformData {
  /// List of amplitude values normalized between 0.0 and 1.0
  final List<double> amplitudes;

  /// Sample rate of the audio in Hz
  final int sampleRate;

  /// Duration of the audio in milliseconds
  final int durationMs;

  /// Number of audio channels
  final int channels;

  /// Optional style configuration for visualization
  final WaveformStyle? style;

  /// Creates new waveform data
  WaveformData({
    required this.amplitudes,
    required this.sampleRate,
    required this.durationMs,
    required this.channels,
    this.style,
  });

  /// Gets the peak amplitude value
  double get peakAmplitude {
    if (amplitudes.isEmpty) return 0.0;
    return amplitudes.reduce((a, b) => a > b ? a : b);
  }

  /// Gets the average amplitude value
  double get averageAmplitude {
    if (amplitudes.isEmpty) return 0.0;
    return amplitudes.reduce((a, b) => a + b) / amplitudes.length;
  }

  /// Gets the number of amplitude samples
  int get sampleCount => amplitudes.length;

  /// Gets the duration in seconds
  double get durationSeconds => durationMs / 1000.0;

  /// Creates a copy of this waveform data with a new style
  WaveformData withStyle(WaveformStyle newStyle) {
    return WaveformData(
      amplitudes: amplitudes,
      sampleRate: sampleRate,
      durationMs: durationMs,
      channels: channels,
      style: newStyle,
    );
  }

  @override
  String toString() {
    return 'WaveformData(samples: ${amplitudes.length}, sampleRate: $sampleRate, '
        'durationMs: $durationMs, channels: $channels, peak: ${peakAmplitude.toStringAsFixed(3)})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WaveformData &&
        other.sampleRate == sampleRate &&
        other.durationMs == durationMs &&
        other.channels == channels &&
        _listEquals(other.amplitudes, amplitudes);
  }

  @override
  int get hashCode {
    return amplitudes.hashCode ^
        sampleRate.hashCode ^
        durationMs.hashCode ^
        channels.hashCode;
  }

  /// Helper method to compare lists
  bool _listEquals(List<double> a, List<double> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if ((a[i] - b[i]).abs() > 0.0001) {
        return false; // Allow small floating point differences
      }
    }
    return true;
  }
}
