import 'package:flutter/material.dart';
import '../models/audio_player_config.dart';
import '../models/audio_player_state.dart';

/// Widget for audio player controls (play/pause, progress, volume, etc.)
class AudioPlayerControls extends StatelessWidget {
  /// State manager for the audio player
  final AudioPlayerStateManager stateManager;

  /// Configuration for the controls
  final AudioPlayerControlsConfig config;

  /// Callback when user seeks to a position
  final void Function(Duration position)? onSeek;

  /// Callback when volume changes
  final void Function(double volume)? onVolumeChanged;

  /// Callback for play/pause toggle
  final VoidCallback? onPlayPause;

  /// Callback for stop
  final VoidCallback? onStop;

  /// Whether this is an overlay (transparent background)
  final bool isOverlay;

  const AudioPlayerControls({
    super.key,
    required this.stateManager,
    required this.config,
    this.onSeek,
    this.onVolumeChanged,
    this.onPlayPause,
    this.onStop,
    this.isOverlay = false,
  });
  @override
  Widget build(BuildContext context) {
    final colors = config.colors ?? const AudioPlayerColors();

    Widget controls;

    switch (config.controlsPosition) {
      case ControlsPosition.top:
      case ControlsPosition.bottom:
        controls = _buildHorizontalControls(colors, context);
        break;

      case ControlsPosition.left:
      case ControlsPosition.right:
        controls = _buildVerticalControls(colors, context);
        break;

      case ControlsPosition.overlay:
        controls = _buildOverlayControls(colors, context);
        break;
    }
    if (isOverlay) {
      return Container(
        decoration: BoxDecoration(
          color: colors.backgroundColor?.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: controls,
      );
    }

    // Use transparent background unless a specific color is set
    return Container(
      decoration: BoxDecoration(
        color: colors.backgroundColor ?? Colors.transparent,
      ),
      child: controls,
    );
  }

  Widget _buildHorizontalControls(
    AudioPlayerColors colors,
    BuildContext context,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Play/Pause button
          if (config.showPlayPause) ...[
            _buildPlayPauseButton(colors),
            const SizedBox(width: 16),
          ],

          // Time label (current)
          if (config.showTimeLabels) ...[
            _buildTimeLabel(stateManager.positionFormatted, colors),
            const SizedBox(width: 16),
          ],

          // Progress slider
          if (config.showProgress)
            Expanded(child: _buildProgressSlider(colors, context)),

          // Time label (remaining/total)
          if (config.showTimeLabels) ...[
            const SizedBox(width: 16),
            _buildTimeLabel(stateManager.durationFormatted, colors),
          ],

          // Volume control
          if (config.showVolumeControl) ...[
            const SizedBox(width: 16),
            _buildVolumeControl(colors, context),
          ],
        ],
      ),
    );
  }

  Widget _buildVerticalControls(
    AudioPlayerColors colors,
    BuildContext context,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Play/Pause button
          if (config.showPlayPause) ...[
            _buildPlayPauseButton(colors),
            const SizedBox(height: 16),
          ],

          // Progress slider (vertical)
          if (config.showProgress) ...[
            Expanded(
              child: RotatedBox(
                quarterTurns: 3,
                child: _buildProgressSlider(colors, context),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Time labels (stacked)
          if (config.showTimeLabels) ...[
            _buildTimeLabel(stateManager.positionFormatted, colors),
            const SizedBox(height: 4),
            _buildTimeLabel(stateManager.durationFormatted, colors),
            const SizedBox(height: 16),
          ],

          // Volume control
          if (config.showVolumeControl) _buildVolumeControl(colors, context),
        ],
      ),
    );
  }

  Widget _buildOverlayControls(AudioPlayerColors colors, BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (config.showPlayPause) _buildPlayPauseButton(colors),
            if (config.showVolumeControl) ...[
              const SizedBox(width: 16),
              _buildVolumeControl(colors, context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlayPauseButton(AudioPlayerColors colors) {
    // Use Material to create a circular button with proper styling
    return Container(
      width: config.buttonSize,
      height: config.buttonSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.transparent, // Transparent background
      ),
      child: Material(
        color: Colors.transparent, // Important: transparent material background
        child: InkWell(
          onTap: config.enabled ? onPlayPause : null,
          borderRadius: BorderRadius.circular(
            config.buttonSize / 2,
          ), // Circular shape
          child: Ink(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.playButtonColor,
            ),
            child: Center(
              child: Icon(
                stateManager.isPlaying ? Icons.pause : Icons.play_arrow,
                color: colors.playIconColor,
                size: config.buttonSize * 0.6,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressSlider(AudioPlayerColors colors, BuildContext context) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        activeTrackColor: colors.progressActiveColor,
        inactiveTrackColor: colors.progressInactiveColor,
        thumbColor: colors.progressThumbColor,
        overlayColor: colors.progressThumbColor.withValues(alpha: 0.2),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
      ),
      child: Slider(
        value: stateManager.progress.clamp(0.0, 1.0),
        onChanged:
            config.enabled
                ? (value) {
                  final position = Duration(
                    milliseconds:
                        (stateManager.duration.inMilliseconds * value).round(),
                  );
                  onSeek?.call(position);
                }
                : null,
      ),
    );
  }

  Widget _buildTimeLabel(String text, AudioPlayerColors colors) {
    return Text(
      text,
      style: TextStyle(
        color: colors.timeLabelColor,
        fontSize: 12,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }

  Widget _buildVolumeControl(AudioPlayerColors colors, BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          stateManager.isMuted || stateManager.volume == 0
              ? Icons.volume_off
              : stateManager.volume < 0.5
              ? Icons.volume_down
              : Icons.volume_up,
          color: colors.volumeColor,
          size: 20,
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 80,
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: colors.volumeColor,
              inactiveTrackColor: colors.volumeColor.withValues(alpha: 0.3),
              thumbColor: colors.volumeColor,
              overlayColor: colors.volumeColor.withValues(alpha: 0.2),
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            ),
            child: Slider(
              value: stateManager.isMuted ? 0 : stateManager.volume,
              onChanged:
                  config.enabled
                      ? (value) {
                        onVolumeChanged?.call(value);
                      }
                      : null,
            ),
          ),
        ),
      ],
    );
  }
}
