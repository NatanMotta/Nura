import 'dart:ui';

/// Style configuration for waveform visualization
class WaveformStyle {
  /// Primary color for the waveform
  final Color primaryColor;

  /// Secondary color for gradients or dual-channel display
  final Color? secondaryColor;

  /// Background color
  final Color backgroundColor;

  /// Style type for rendering
  final WaveformStyleType styleType;

  /// Line width for waveform rendering
  final double lineWidth;

  /// Opacity for the waveform (0.0 to 1.0)
  final double opacity;

  /// Whether to use gradient fill
  final bool useGradient;

  /// Whether to show grid lines
  final bool showGrid;

  /// Grid color
  final Color gridColor;

  /// Creates a new waveform style configuration
  const WaveformStyle({
    required this.primaryColor,
    this.secondaryColor,
    this.backgroundColor = const Color(0xFF000000),
    this.styleType = WaveformStyleType.filled,
    this.lineWidth = 2.0,
    this.opacity = 1.0,
    this.useGradient = false,
    this.showGrid = false,
    this.gridColor = const Color(0xFF333333),
  });

  /// Creates a copy of this style with optional parameter overrides
  WaveformStyle copyWith({
    Color? primaryColor,
    Color? secondaryColor,
    Color? backgroundColor,
    WaveformStyleType? styleType,
    double? lineWidth,
    double? opacity,
    bool? useGradient,
    bool? showGrid,
    Color? gridColor,
  }) {
    return WaveformStyle(
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      styleType: styleType ?? this.styleType,
      lineWidth: lineWidth ?? this.lineWidth,
      opacity: opacity ?? this.opacity,
      useGradient: useGradient ?? this.useGradient,
      showGrid: showGrid ?? this.showGrid,
      gridColor: gridColor ?? this.gridColor,
    );
  }

  @override
  String toString() {
    return 'WaveformStyle(primaryColor: $primaryColor, styleType: $styleType, '
        'lineWidth: $lineWidth, opacity: $opacity)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WaveformStyle &&
        other.primaryColor == primaryColor &&
        other.secondaryColor == secondaryColor &&
        other.backgroundColor == backgroundColor &&
        other.styleType == styleType &&
        other.lineWidth == lineWidth &&
        other.opacity == opacity &&
        other.useGradient == useGradient &&
        other.showGrid == showGrid &&
        other.gridColor == gridColor;
  }

  @override
  int get hashCode {
    return Object.hash(
      primaryColor,
      secondaryColor,
      backgroundColor,
      styleType,
      lineWidth,
      opacity,
      useGradient,
      showGrid,
      gridColor,
    );
  }
}

/// Types of waveform rendering styles
enum WaveformStyleType {
  /// Filled waveform with solid color
  filled,

  /// Line-only waveform outline
  line,

  /// Bars/columns representing amplitude
  bars,

  /// Points/dots for each sample
  points,

  /// Mirrored waveform (top and bottom)
  mirrored,

  /// Frequency spectrum style
  spectrum,
}

/// Predefined color schemes for waveforms
class WaveformColorSchemes {
  /// Classic blue waveform
  static const WaveformStyle classic = WaveformStyle(
    primaryColor: Color(0xFF2196F3),
    backgroundColor: Color(0xFF000000),
    styleType: WaveformStyleType.filled,
  );

  /// Fire/heat color scheme
  static const WaveformStyle fire = WaveformStyle(
    primaryColor: Color(0xFFFF5722),
    secondaryColor: Color(0xFFFFC107),
    backgroundColor: Color(0xFF000000),
    styleType: WaveformStyleType.filled,
    useGradient: true,
  );

  /// Ocean/water color scheme
  static const WaveformStyle ocean = WaveformStyle(
    primaryColor: Color(0xFF00BCD4),
    secondaryColor: Color(0xFF3F51B5),
    backgroundColor: Color(0xFF0D1421),
    styleType: WaveformStyleType.filled,
    useGradient: true,
  );

  /// Forest/nature color scheme
  static const WaveformStyle forest = WaveformStyle(
    primaryColor: Color(0xFF4CAF50),
    secondaryColor: Color(0xFF8BC34A),
    backgroundColor: Color(0xFF1B5E20),
    styleType: WaveformStyleType.filled,
    useGradient: true,
  );

  /// Neon/cyberpunk color scheme
  static const WaveformStyle neon = WaveformStyle(
    primaryColor: Color(0xFFE91E63),
    secondaryColor: Color(0xFF9C27B0),
    backgroundColor: Color(0xFF000000),
    styleType: WaveformStyleType.line,
    lineWidth: 3.0,
    useGradient: true,
  );

  /// Monochrome/grayscale scheme
  static const WaveformStyle monochrome = WaveformStyle(
    primaryColor: Color(0xFFFFFFFF),
    backgroundColor: Color(0xFF000000),
    styleType: WaveformStyleType.filled,
  );

  /// Sunset color scheme
  static const WaveformStyle sunset = WaveformStyle(
    primaryColor: Color(0xFFFF9800),
    secondaryColor: Color(0xFFE91E63),
    backgroundColor: Color(0xFF3E2723),
    styleType: WaveformStyleType.filled,
    useGradient: true,
  );

  /// Professional/business scheme
  static const WaveformStyle professional = WaveformStyle(
    primaryColor: Color(0xFF607D8B),
    backgroundColor: Color(0xFFF5F5F5),
    styleType: WaveformStyleType.bars,
    showGrid: true,
  );

  /// Music visualizer scheme
  static const WaveformStyle visualizer = WaveformStyle(
    primaryColor: Color(0xFF9C27B0),
    secondaryColor: Color(0xFF673AB7),
    backgroundColor: Color(0xFF000000),
    styleType: WaveformStyleType.spectrum,
    useGradient: true,
  );

  /// Get all predefined color schemes
  static List<WaveformStyle> get allSchemes => [
    classic,
    fire,
    ocean,
    forest,
    neon,
    monochrome,
    sunset,
    professional,
    visualizer,
  ];
}
