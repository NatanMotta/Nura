import 'package:flutter/foundation.dart';
import 'audio_player_config.dart';
import 'waveform_data.dart';

/// State management for audio player with waveform visualization
class AudioPlayerStateManager extends ChangeNotifier {
  /// Current playback state
  AudioPlayerState _state = AudioPlayerState.stopped;

  /// Current playback position
  Duration _position = Duration.zero;

  /// Total duration of the audio
  Duration _duration = Duration.zero;

  /// Current volume (0.0 to 1.0)
  double _volume = 1.0;

  /// Whether the player is muted
  bool _isMuted = false;

  /// Current audio file path
  String? _audioPath;

  /// Waveform data for visualization
  WaveformData? _waveformData;

  /// Current error message if any
  String? _errorMessage;

  /// Whether the player is initialized
  bool _isInitialized = false;

  /// Playback speed (0.25 to 4.0)
  double _playbackSpeed = 1.0;

  // Getters
  AudioPlayerState get state => _state;
  Duration get position => _position;
  Duration get duration => _duration;
  double get volume => _volume;
  bool get isMuted => _isMuted;
  String? get audioPath => _audioPath;
  WaveformData? get waveformData => _waveformData;
  String? get errorMessage => _errorMessage;
  bool get isInitialized => _isInitialized;
  double get playbackSpeed => _playbackSpeed;

  /// Whether the player is currently playing
  bool get isPlaying => _state == AudioPlayerState.playing;

  /// Whether the player is paused
  bool get isPaused => _state == AudioPlayerState.paused;

  /// Whether the player is stopped
  bool get isStopped => _state == AudioPlayerState.stopped;

  /// Whether the player is loading
  bool get isLoading => _state == AudioPlayerState.loading;

  /// Whether the player has an error
  bool get hasError => _state == AudioPlayerState.error;

  /// Progress as a value between 0.0 and 1.0
  double get progress {
    if (_duration.inMilliseconds == 0) return 0.0;
    return _position.inMilliseconds / _duration.inMilliseconds;
  }

  /// Remaining time
  Duration get remainingTime => _duration - _position;

  /// Formatted current position (MM:SS)
  String get positionFormatted => _formatDuration(_position);

  /// Formatted total duration (MM:SS)
  String get durationFormatted => _formatDuration(_duration);

  /// Formatted remaining time (MM:SS)
  String get remainingTimeFormatted => _formatDuration(remainingTime);

  /// Updates the playback state
  void updateState(AudioPlayerState newState) {
    if (_state != newState) {
      _state = newState;
      notifyListeners();
    }
  }

  /// Updates the current position
  void updatePosition(Duration newPosition) {
    if (_position != newPosition) {
      _position = newPosition;
      notifyListeners();
    }
  }

  /// Updates the total duration
  void updateDuration(Duration newDuration) {
    if (_duration != newDuration) {
      _duration = newDuration;
      notifyListeners();
    }
  }

  /// Updates the volume
  void updateVolume(double newVolume) {
    newVolume = newVolume.clamp(0.0, 1.0);
    if (_volume != newVolume) {
      _volume = newVolume;
      if (newVolume > 0) {
        _isMuted = false;
      }
      notifyListeners();
    }
  }

  /// Toggles mute state
  void toggleMute() {
    _isMuted = !_isMuted;
    notifyListeners();
  }

  /// Sets the audio file path
  void setAudioPath(String? path) {
    if (_audioPath != path) {
      _audioPath = path;
      _isInitialized = path != null;
      notifyListeners();
    }
  }

  /// Sets the waveform data
  void setWaveformData(WaveformData? data) {
    if (data == null) {
      return;
    }

    if (data.amplitudes.isEmpty) {
      return;
    }

    // Always set this for streams - do a deep check only if needed
    _waveformData = data;
    notifyListeners();
  }

  /// Sets an error message
  void setError(String? error) {
    if (_errorMessage != error) {
      _errorMessage = error;
      if (error != null) {
        _state = AudioPlayerState.error;
      }
      notifyListeners();
    }
  }

  /// Clears any error
  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      if (_state == AudioPlayerState.error) {
        _state = AudioPlayerState.stopped;
      }
      notifyListeners();
    }
  }

  /// Sets the playback speed
  void setPlaybackSpeed(double speed) {
    speed = speed.clamp(0.25, 4.0);
    if (_playbackSpeed != speed) {
      _playbackSpeed = speed;
      notifyListeners();
    }
  }

  /// Resets the player to initial state
  void reset() {
    _state = AudioPlayerState.stopped;
    _position = Duration.zero;
    _duration = Duration.zero;
    _volume = 1.0;
    _isMuted = false;
    _audioPath = null;
    _waveformData = null;
    _errorMessage = null;
    _isInitialized = false;
    _playbackSpeed = 1.0;
    notifyListeners();
  }

  /// Seeks to a specific position as a percentage (0.0 to 1.0)
  void seekToProgress(double progress) {
    progress = progress.clamp(0.0, 1.0);
    final newPosition = Duration(
      milliseconds: (_duration.inMilliseconds * progress).round(),
    );
    updatePosition(newPosition);
  }

  /// Seeks to a specific time position
  void seekToPosition(Duration position) {
    position = Duration(
      milliseconds: position.inMilliseconds.clamp(0, _duration.inMilliseconds),
    );
    updatePosition(position);
  }

  /// Gets the waveform position for the current playback position
  int get waveformPosition {
    if (_waveformData == null || _duration.inMilliseconds == 0) return 0;
    final progressRatio = _position.inMilliseconds / _duration.inMilliseconds;
    return (progressRatio * _waveformData!.amplitudes.length).round();
  }

  /// Formats a duration to MM:SS or HH:MM:SS format
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }
  }

  @override
  void dispose() {
    // Clean up any resources
    super.dispose();
  }
}
