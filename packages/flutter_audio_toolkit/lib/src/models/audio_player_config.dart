import 'package:flutter/material.dart';
import 'waveform_style.dart';

/// Configuration for audio player controls
class AudioPlayerControlsConfig {
  /// Whether to show play/pause button
  final bool showPlayPause;

  /// Whether to show progress slider
  final bool showProgress;

  /// Whether to show time labels
  final bool showTimeLabels;

  /// Whether to show volume control
  final bool showVolumeControl;

  /// Size of control buttons
  final double buttonSize;

  /// Position of controls relative to waveform
  final ControlsPosition controlsPosition;

  /// Custom control button colors
  final AudioPlayerColors? colors;

  /// Whether controls are enabled
  final bool enabled;

  const AudioPlayerControlsConfig({
    this.showPlayPause = true,
    this.showProgress = true,
    this.showTimeLabels = true,
    this.showVolumeControl = false,
    this.buttonSize = 48.0,
    this.controlsPosition = ControlsPosition.bottom,
    this.colors,
    this.enabled = true,
  });

  /// Creates a copy with modified properties
  AudioPlayerControlsConfig copyWith({
    bool? showPlayPause,
    bool? showProgress,
    bool? showTimeLabels,
    bool? showVolumeControl,
    double? buttonSize,
    ControlsPosition? controlsPosition,
    AudioPlayerColors? colors,
    bool? enabled,
  }) {
    return AudioPlayerControlsConfig(
      showPlayPause: showPlayPause ?? this.showPlayPause,
      showProgress: showProgress ?? this.showProgress,
      showTimeLabels: showTimeLabels ?? this.showTimeLabels,
      showVolumeControl: showVolumeControl ?? this.showVolumeControl,
      buttonSize: buttonSize ?? this.buttonSize,
      controlsPosition: controlsPosition ?? this.controlsPosition,
      colors: colors ?? this.colors,
      enabled: enabled ?? this.enabled,
    );
  }
}

/// Position of audio player controls
enum ControlsPosition {
  /// Controls above waveform
  top,

  /// Controls below waveform
  bottom,

  /// Controls overlay on waveform
  overlay,

  /// Controls on the left side
  left,

  /// Controls on the right side
  right,
}

/// Color scheme for audio player controls
class AudioPlayerColors {
  /// Play/pause button color
  final Color playButtonColor;

  /// Play/pause button icon color
  final Color playIconColor;

  /// Progress bar active color
  final Color progressActiveColor;

  /// Progress bar inactive color
  final Color progressInactiveColor;

  /// Progress bar thumb color
  final Color progressThumbColor;

  /// Time label text color
  final Color timeLabelColor;

  /// Volume control color
  final Color volumeColor;

  /// Background color for controls
  final Color? backgroundColor;
  const AudioPlayerColors({
    this.playButtonColor = Colors.blue,
    this.playIconColor = Colors.white,
    this.progressActiveColor = Colors.blue,
    this.progressInactiveColor = Colors.grey,
    this.progressThumbColor = Colors.blue,
    this.timeLabelColor = Colors.black87,
    this.volumeColor = Colors.grey,
    this.backgroundColor,
  });

  /// Creates a copy with modified colors
  AudioPlayerColors copyWith({
    Color? playButtonColor,
    Color? playIconColor,
    Color? progressActiveColor,
    Color? progressInactiveColor,
    Color? progressThumbColor,
    Color? timeLabelColor,
    Color? volumeColor,
    Color? backgroundColor,
  }) {
    return AudioPlayerColors(
      playButtonColor: playButtonColor ?? this.playButtonColor,
      playIconColor: playIconColor ?? this.playIconColor,
      progressActiveColor: progressActiveColor ?? this.progressActiveColor,
      progressInactiveColor:
          progressInactiveColor ?? this.progressInactiveColor,
      progressThumbColor: progressThumbColor ?? this.progressThumbColor,
      timeLabelColor: timeLabelColor ?? this.timeLabelColor,
      volumeColor: volumeColor ?? this.volumeColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
    );
  }
}

/// State of the audio player
enum AudioPlayerState {
  /// Player is stopped
  stopped,

  /// Player is playing
  playing,

  /// Player is paused
  paused,

  /// Player is loading
  loading,

  /// Player encountered an error
  error,
}

/// Configuration for waveform visualization in the audio player
class WaveformVisualizationConfig {
  /// Style for the waveform
  final WaveformStyle style;

  /// Height of the waveform widget
  final double height;

  /// Whether to show playback position indicator
  final bool showPosition;

  /// Color of the playback position indicator
  final Color positionIndicatorColor;

  /// Width of the playback position indicator
  final double positionIndicatorWidth;

  /// Whether waveform is interactive (tap to seek)
  final bool interactive;

  /// Whether to show progress overlay
  final bool showProgress;

  /// Color of played portion of waveform
  final Color? playedColor;

  const WaveformVisualizationConfig({
    required this.style,
    this.height = 80.0,
    this.showPosition = true,
    this.positionIndicatorColor = Colors.red,
    this.positionIndicatorWidth = 2.0,
    this.interactive = true,
    this.showProgress = true,
    this.playedColor,
  });

  /// Creates a copy with modified properties
  WaveformVisualizationConfig copyWith({
    WaveformStyle? style,
    double? height,
    bool? showPosition,
    Color? positionIndicatorColor,
    double? positionIndicatorWidth,
    bool? interactive,
    bool? showProgress,
    Color? playedColor,
  }) {
    return WaveformVisualizationConfig(
      style: style ?? this.style,
      height: height ?? this.height,
      showPosition: showPosition ?? this.showPosition,
      positionIndicatorColor:
          positionIndicatorColor ?? this.positionIndicatorColor,
      positionIndicatorWidth:
          positionIndicatorWidth ?? this.positionIndicatorWidth,
      interactive: interactive ?? this.interactive,
      showProgress: showProgress ?? this.showProgress,
      playedColor: playedColor ?? this.playedColor,
    );
  }
}

/// Audio player event callbacks
class AudioPlayerCallbacks {
  /// Called when playback state changes
  final void Function(AudioPlayerState state)? onStateChanged;

  /// Called when position changes during playback
  final void Function(Duration position)? onPositionChanged;

  /// Called when duration is determined
  final void Function(Duration duration)? onDurationChanged;

  /// Called when user seeks to a position
  final void Function(Duration position)? onSeek;

  /// Called when volume changes
  final void Function(double volume)? onVolumeChanged;

  /// Called when an error occurs
  final void Function(String error)? onError;

  const AudioPlayerCallbacks({
    this.onStateChanged,
    this.onPositionChanged,
    this.onDurationChanged,
    this.onSeek,
    this.onVolumeChanged,
    this.onError,
  });
}
