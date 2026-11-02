import 'package:flutter/material.dart';
import '../models/waveform_data.dart';
import '../models/audio_player_config.dart';

/// Widget for visualizing waveform data with playback position
class WaveformVisualizer extends StatelessWidget {
  /// Waveform data to visualize
  final WaveformData? waveformData;

  /// Configuration for the visualization
  final WaveformVisualizationConfig config;

  /// Current playback position
  final Duration currentPosition;

  /// Total duration of the audio
  final Duration duration;

  /// Callback when user taps to seek
  final void Function(Duration position)? onSeek;

  const WaveformVisualizer({
    super.key,
    required this.waveformData,
    required this.config,
    required this.currentPosition,
    required this.duration,
    this.onSeek,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: config.height,
      child:
          waveformData == null ? _buildPlaceholder() : _buildWaveform(context),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Center(
        child: Text('No waveform data', style: TextStyle(color: Colors.grey)),
      ),
    );
  }

  Widget _buildWaveform(BuildContext context) {
    // Additional check to ensure waveform data is valid
    if (waveformData == null || waveformData!.amplitudes.isEmpty) {
      return _buildPlaceholder();
    }

    return GestureDetector(
      onTapDown: config.interactive ? _handleTap : null,
      child: CustomPaint(
        painter: WaveformPainter(
          waveformData: waveformData!,
          config: config,
          currentPosition: currentPosition,
          duration: duration,
        ),
        size: Size.infinite,
      ),
    );
  }

  void _handleTap(TapDownDetails details) {
    if (onSeek == null || duration.inMilliseconds == 0) return;

    final localPosition = details.localPosition;
    // We need to get the widget width from the context
    // For now, we'll use a reasonable default or get it from renderbox
    final widgetWidth =
        300.0; // This should be size.width but we don't have access here

    final tapRatio = localPosition.dx / widgetWidth;
    final seekPosition = Duration(
      milliseconds: (duration.inMilliseconds * tapRatio).round(),
    );

    onSeek!(seekPosition);
  }
}

/// Custom painter for waveform visualization
class WaveformPainter extends CustomPainter {
  final WaveformData waveformData;
  final WaveformVisualizationConfig config;
  final Duration currentPosition;
  final Duration duration;

  WaveformPainter({
    required this.waveformData,
    required this.config,
    required this.currentPosition,
    required this.duration,
  });
  @override
  void paint(Canvas canvas, Size size) {
    final height = size.height;
    final centerY = height / 2;

    // Calculate progress
    final progress =
        duration.inMilliseconds > 0
            ? currentPosition.inMilliseconds / duration.inMilliseconds
            : 0.0;

    // Draw waveform bars
    _drawWaveformBars(canvas, size, centerY, progress);

    // Draw playback position indicator
    if (config.showPosition) {
      _drawPositionIndicator(canvas, size, progress);
    }
  }

  void _drawWaveformBars(
    Canvas canvas,
    Size size,
    double centerY,
    double progress,
  ) {
    final amplitudes = waveformData.amplitudes;
    if (amplitudes.isEmpty) return;

    final barWidth = size.width / amplitudes.length;
    final maxHeight = size.height * 0.8; // Leave some padding

    for (int i = 0; i < amplitudes.length; i++) {
      final x = i * barWidth;
      final amplitude = amplitudes[i].clamp(0.0, 1.0);
      final barHeight = amplitude * maxHeight;

      // Determine bar color based on playback progress
      final barProgress = i / amplitudes.length;
      Color barColor;

      if (config.showProgress && barProgress <= progress) {
        // Played portion
        barColor = config.playedColor ?? config.style.primaryColor;
      } else {
        // Unplayed portion
        barColor = config.style.primaryColor.withValues(
          alpha: config.style.opacity * 0.5,
        );
      }

      // Create gradient effect if useGradient is enabled
      Paint paint;
      if (config.style.useGradient && config.style.secondaryColor != null) {
        paint =
            Paint()
              ..shader = LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors:
                    barProgress <= progress
                        ? [
                          config.style.primaryColor,
                          config.style.secondaryColor!,
                        ]
                        : [
                          config.style.primaryColor.withValues(
                            alpha: config.style.opacity * 0.5,
                          ),
                          config.style.secondaryColor!.withValues(
                            alpha: config.style.opacity * 0.5,
                          ),
                        ],
              ).createShader(
                Rect.fromLTWH(x, centerY - barHeight / 2, barWidth, barHeight),
              );
      } else {
        paint =
            Paint()..color = barColor.withValues(alpha: config.style.opacity);
      }

      // Draw the waveform bar (centered)
      final rect = Rect.fromLTWH(
        x,
        centerY - barHeight / 2,
        barWidth * 0.8, // Slight gap between bars
        barHeight,
      );

      // Simple rectangle drawing (no custom border radius)
      canvas.drawRect(rect, paint);

      // Draw border using lineWidth if greater than 0
      if (config.style.lineWidth > 0) {
        final borderPaint =
            Paint()
              ..color = config.style.primaryColor.withValues(alpha: 0.8)
              ..style = PaintingStyle.stroke
              ..strokeWidth = config.style.lineWidth;

        canvas.drawRect(rect, borderPaint);
      }
    }
  }

  void _drawPositionIndicator(Canvas canvas, Size size, double progress) {
    final x = size.width * progress.clamp(0.0, 1.0);

    final paint =
        Paint()
          ..color = config.positionIndicatorColor
          ..strokeWidth = config.positionIndicatorWidth;

    // Draw vertical line
    canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);

    // Draw small circle at top for better visibility
    final circlePaint = Paint()..color = config.positionIndicatorColor;

    canvas.drawCircle(Offset(x, 4), 4, circlePaint);
  }

  @override
  bool shouldRepaint(WaveformPainter oldDelegate) {
    return oldDelegate.currentPosition != currentPosition ||
        oldDelegate.duration != duration ||
        oldDelegate.waveformData != waveformData ||
        oldDelegate.config != config;
  }
}
