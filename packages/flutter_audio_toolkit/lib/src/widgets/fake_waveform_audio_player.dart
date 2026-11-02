import 'dart:io';
import 'package:flutter/material.dart';
import '../models/audio_player_config.dart';
import '../models/audio_player_state.dart';
import '../models/waveform_pattern.dart';
import '../core/audio_player_service.dart';
import '../core/audio_service.dart';
import '../utils/path_provider_util.dart';
import '../utils/audio_error_handler.dart';
import 'audio_player_controls.dart';
import 'waveform_visualizer.dart';

/// Audio player widget with fake waveform visualization
/// Supports both local files and network URLs
class FakeWaveformAudioPlayer extends StatefulWidget {
  /// Path to the audio file (local path or URL)
  final String audioPath;

  /// Configuration for the waveform visualization
  final WaveformVisualizationConfig waveformConfig;

  /// Configuration for the player controls
  final AudioPlayerControlsConfig controlsConfig;

  /// Waveform pattern to generate
  final WaveformPattern waveformPattern;

  /// Number of samples per second for fake waveform
  final int samplesPerSecond;

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

  /// Temporary path for downloaded network files (when audioPath is URL)
  /// If not provided, a default temporary path will be used
  final String? tempPath;
  const FakeWaveformAudioPlayer({
    super.key,
    required this.audioPath,
    required this.waveformConfig,
    this.controlsConfig = const AudioPlayerControlsConfig(),
    this.waveformPattern = WaveformPattern.music,
    this.samplesPerSecond = 100,
    this.callbacks,
    this.playerId,
    this.autoLoad = true,
    this.loadingWidget,
    this.errorWidget,
    this.tempPath,
  });

  @override
  State<FakeWaveformAudioPlayer> createState() =>
      _FakeWaveformAudioPlayerState();
}

class _FakeWaveformAudioPlayerState extends State<FakeWaveformAudioPlayer> {
  late AudioPlayerService _playerService;
  late AudioPlayerStateManager _stateManager;
  // For network files, this holds the local downloaded path

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

  /// Checks if the provided path is a URL
  bool _isUrl(String path) {
    return path.startsWith('http://') || path.startsWith('https://');
  }

  /// Generates a temporary file path for network downloads
  Future<String> _getTempPath() async {
    if (widget.tempPath != null) {
      return widget.tempPath!;
    }

    try {
      return await PathProviderUtil.createTempFilePath(
        prefix: 'flutter_audio_toolkit',
        suffix: '.tmp',
        playerId: widget.playerId,
      );
    } catch (e) {
      // Fallback to basic temp path
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final playerId = widget.playerId ?? 'default';
      return '/tmp/flutter_audio_toolkit_${playerId}_$timestamp.tmp';
    }
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
        final userFriendlyMessage = AudioErrorHandler.getUserFriendlyMessage(
          _stateManager.errorMessage!,
        );
        widget.callbacks?.onError?.call(userFriendlyMessage);
      }
    } catch (e) {
      // Don't rethrow to avoid breaking the entire widget
    }
  }

  Future<void> _loadAudio() async {
    try {
      if (_isUrl(widget.audioPath)) {
        // Handle network URL
        await _loadAudioFromUrl();
      } else {
        // Handle local file
        await _loadAudioFromLocalFile();
      }
    } catch (e) {
      if (mounted) {
        setState(() {});
      }
    }
  }

  /// Loads audio from a network URL
  Future<void> _loadAudioFromUrl() async {
    var tempPath = await _getTempPath();

    try {
      // Handle different platforms for temp path
      try {
        final tempDir = Directory(tempPath).parent;
        if (!await tempDir.exists()) {
          await tempDir.create(recursive: true);
        }
      } catch (e) {
        // Fallback to a simpler path if needed
        try {
          tempPath = await PathProviderUtil.createTempFilePath(
            prefix: 'temp_audio',
            suffix: '.tmp',
          );
        } catch (e2) {
          tempPath =
              '${Directory.systemTemp.path}/temp_audio_${DateTime.now().millisecondsSinceEpoch}.tmp';
        }
      }

      // First download the file, then load with fake waveform

      await AudioService.downloadFile(
        widget.audioPath,
        tempPath,
        onProgress: (progress) {
          widget.callbacks?.onPositionChanged?.call(
            Duration(milliseconds: (progress * 100).round()),
          );
        },
      );

      final file = File(tempPath);
      final exists = await file.exists();
      final size = exists ? await file.length() : 0;

      if (!exists || size == 0) {
        throw Exception('Downloaded file is missing or empty: $tempPath');
      }

      // Now load the downloaded file

      await _playerService.loadAudioWithFakeWaveform(
        tempPath,
        pattern: widget.waveformPattern,
        samplesPerSecond: widget.samplesPerSecond,
      );

      // Validate waveform data was created
      final hasWaveform =
          _stateManager.waveformData != null &&
          _stateManager.waveformData!.amplitudes.isNotEmpty;

      if (!hasWaveform) {
        // Fallback if waveform wasn't generated

        // Try with a simpler pattern as fallback
        await _playerService.loadAudioWithFakeWaveform(
          tempPath,
          pattern: WaveformPattern.sine, // Simpler pattern
          samplesPerSecond: widget.samplesPerSecond,
        );
      }
    } catch (e) {
      // Clean up temp file on error
      try {
        await PathProviderUtil.cleanupFile(tempPath);
      } catch (cleanupError) {
        // Ignore cleanup errors
      }

      rethrow;
    }
  }

  /// Loads audio from a local file
  Future<void> _loadAudioFromLocalFile() async {
    await _playerService.loadAudioWithFakeWaveform(
      widget.audioPath,
      pattern: widget.waveformPattern,
      samplesPerSecond: widget.samplesPerSecond,
    );
  }

  void _onSeek(Duration position) {
    try {
      if (!_playerService.isDisposed) {
        _playerService.seekTo(position);
        widget.callbacks?.onSeek?.call(position);
      }
    } catch (e) {
      AudioErrorHandler.logError(e, context: 'FakeWaveformAudioPlayer.seek');
      widget.callbacks?.onError?.call(
        AudioErrorHandler.getUserFriendlyMessage(e),
      );
    }
  }

  void _onVolumeChanged(double volume) {
    try {
      if (!_playerService.isDisposed) {
        _playerService.setVolume(volume);
        widget.callbacks?.onVolumeChanged?.call(volume);
      }
    } catch (e) {
      AudioErrorHandler.logError(e, context: 'FakeWaveformAudioPlayer.volume');
      widget.callbacks?.onError?.call(
        AudioErrorHandler.getUserFriendlyMessage(e),
      );
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
