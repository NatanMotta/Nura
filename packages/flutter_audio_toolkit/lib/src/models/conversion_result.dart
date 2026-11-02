/// Represents the result of an audio conversion operation
class ConversionResult {
  /// Path to the converted output file
  final String outputPath;

  /// Duration of the audio in milliseconds
  final int durationMs;

  /// Bit rate of the output audio in kbps
  final int bitRate;

  /// Sample rate of the output audio in Hz
  final int sampleRate;

  /// Creates a new conversion result
  ConversionResult({
    required this.outputPath,
    required this.durationMs,
    required this.bitRate,
    required this.sampleRate,
  });

  @override
  String toString() {
    return 'ConversionResult(outputPath: $outputPath, durationMs: $durationMs, '
        'bitRate: $bitRate, sampleRate: $sampleRate)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ConversionResult &&
        other.outputPath == outputPath &&
        other.durationMs == durationMs &&
        other.bitRate == bitRate &&
        other.sampleRate == sampleRate;
  }

  @override
  int get hashCode {
    return outputPath.hashCode ^
        durationMs.hashCode ^
        bitRate.hashCode ^
        sampleRate.hashCode;
  }
}
