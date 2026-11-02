import 'package:flutter/material.dart';
import '../models/audio_player_config.dart';
import '../models/audio_player_state.dart';
import '../core/audio_player_service.dart';
import 'audio_player_controls.dart';
import 'waveform_visualizer.dart';

/// Audio player widget with true waveform visualization
class TrueWaveformAudioPlayer extends StatefulWidget {
  /// Path to the audio file
  final String audioPath;

  /// Configuration for the waveform visualization
  final WaveformVisualizationConfig waveformConfig;

  /// Configuration for the player controls
  final AudioPlayerControlsConfig controlsConfig;

  /// Callbacks for player events
  final AudioPlayerCallbacks? callbacks;

  /// Custom player ID (optional)
  final String? playerId;

  /// Whether to start loading immediately
  final bool autoLoad;

  /// Widget to show while loading
  final Widget? loadingWidget;

  /// Widget to show when there's an error
  final Widget? errorWidget;

  const TrueWaveformAudioPlayer({
    super.key,
    required this.audioPath,
    required this.waveformConfig,
    this.controlsConfig = const AudioPlayerControlsConfig(),
    this.callbacks,
    this.playerId,
    this.autoLoad = true,
    this.loadingWidget,
    this.errorWidget,
  });

  @override
  State<TrueWaveformAudioPlayer> createState() =>
      _TrueWaveformAudioPlayerState();
}

class _TrueWaveformAudioPlayerState extends State<TrueWaveformAudioPlayer> {
  late AudioPlayerService _playerService;
  late AudioPlayerStateManager _stateManager;

  @override
  void initState() {
    super.initState();
    _playerService = AudioPlayerService.create(playerId: widget.playerId);
    _stateManager = _playerService.stateManager;

    // Set up callbacks
    _stateManager.addListener(_onPlayerStateChanged);

    if (widget.autoLoad) {
      _loadAudio();
    }
  }

  @override
  void dispose() {
    _stateManager.removeListener(_onPlayerStateChanged);
    _playerService.dispose();
    super.dispose();
  }

  void _onPlayerStateChanged() {
    // Check if widget is still mounted and player is not disposed
    if (!mounted || _playerService.isDisposed) {
      return;
    }

    try {
      widget.callbacks?.onStateChanged?.call(_stateManager.state);
      widget.callbacks?.onPositionChanged?.call(_stateManager.position);
      widget.callbacks?.onDurationChanged?.call(_stateManager.duration);

      if (_stateManager.hasError && _stateManager.errorMessage != null) {
        widget.callbacks?.onError?.call(_stateManager.errorMessage!);
      }
    } catch (e) {
      // Don't rethrow to avoid breaking the entire widget
    }
  }

  Future<void> _loadAudio() async {
    try {
      await _playerService.loadAudioWithTrueWaveform(widget.audioPath);
    } catch (e) {
      if (mounted) {
        setState(() {});
      }
    }
  }

  void _onSeek(Duration position) {
    try {
      if (!_playerService.isDisposed) {
        _playerService.seekTo(position);
        widget.callbacks?.onSeek?.call(position);
      }
    } catch (e) {
      widget.callbacks?.onError?.call('Seek failed: ${e.toString()}');
    }
  }

  void _onVolumeChanged(double volume) {
    try {
      if (!_playerService.isDisposed) {
        _playerService.setVolume(volume);
        widget.callbacks?.onVolumeChanged?.call(volume);
      }
    } catch (e) {
      widget.callbacks?.onError?.call('Volume change failed: ${e.toString()}');
    }
  }

  Widget _buildLoadingWidget() {
    return widget.loadingWidget ??
        SizedBox(
          height: widget.waveformConfig.height,
          child: const Center(child: CircularProgressIndicator()),
        );
  }

  Widget _buildErrorWidget() {
    return widget.errorWidget ??
        SizedBox(
          height: widget.waveformConfig.height,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 32),
                const SizedBox(height: 8),
                Text(
                  _stateManager.errorMessage ?? 'Failed to load audio',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _loadAudio,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
  }

  Widget _buildWaveformPlayer() {
    return ListenableBuilder(
      listenable: _stateManager,
      builder: (context, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top controls
            if (widget.controlsConfig.controlsPosition == ControlsPosition.top)
              AudioPlayerControls(
                stateManager: _stateManager,
                config: widget.controlsConfig,
                onSeek: _onSeek,
                onVolumeChanged: _onVolumeChanged,
                onPlayPause: _playerService.togglePlayPause,
                onStop: _playerService.stop,
              ),

            // Waveform visualization
            Stack(
              children: [
                WaveformVisualizer(
                  waveformData: _stateManager.waveformData,
                  config: widget.waveformConfig,
                  currentPosition: _stateManager.position,
                  duration: _stateManager.duration,
                  onSeek: widget.waveformConfig.interactive ? _onSeek : null,
                ),

                // Overlay controls
                if (widget.controlsConfig.controlsPosition ==
                    ControlsPosition.overlay)
                  Positioned.fill(
                    child: AudioPlayerControls(
                      stateManager: _stateManager,
                      config: widget.controlsConfig,
                      onSeek: _onSeek,
                      onVolumeChanged: _onVolumeChanged,
                      onPlayPause: _playerService.togglePlayPause,
                      onStop: _playerService.stop,
                      isOverlay: true,
                    ),
                  ),
              ],
            ),

            // Bottom controls
            if (widget.controlsConfig.controlsPosition ==
                ControlsPosition.bottom)
              AudioPlayerControls(
                stateManager: _stateManager,
                config: widget.controlsConfig,
                onSeek: _onSeek,
                onVolumeChanged: _onVolumeChanged,
                onPlayPause: _playerService.togglePlayPause,
                onStop: _playerService.stop,
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _stateManager,
      builder: (context, child) {
        if (_stateManager.isLoading) {
          return _buildLoadingWidget();
        }

        if (_stateManager.hasError) {
          return _buildErrorWidget();
        }

        return _buildWaveformPlayer();
      },
    );
  }
}
