/// Utility class for handling common audio player errors and providing user-friendly messages
class AudioErrorHandler {
  /// Maps common error types to user-friendly messages
  static String getUserFriendlyMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    // Check for disposed player errors
    if (errorString.contains('disposed') ||
        errorString.contains('has been disposed')) {
      return 'The audio player has been stopped. Please reload the audio file.';
    }

    // Check for network/HTTP errors
    if (errorString.contains('http 400') ||
        errorString.contains('bad request')) {
      return 'The audio file URL is invalid or the server cannot process the request.';
    }

    if (errorString.contains('http 401') ||
        errorString.contains('unauthorized')) {
      return 'Authentication is required to access this audio file.';
    }

    if (errorString.contains('http 403') || errorString.contains('forbidden')) {
      return 'Access to this audio file is denied.';
    }

    if (errorString.contains('http 404') || errorString.contains('not found')) {
      return 'The audio file was not found at the specified URL.';
    }

    if (errorString.contains('timeout') ||
        errorString.contains('request timeout')) {
      return 'The request timed out. Please check your internet connection and try again.';
    }

    if (errorString.contains('http 429') ||
        errorString.contains('too many requests')) {
      return 'Too many requests. Please wait a moment and try again.';
    }

    if (errorString.contains('http 500') ||
        errorString.contains('internal server error')) {
      return 'The server encountered an error. Please try again later.';
    }

    if (errorString.contains('http 502') ||
        errorString.contains('bad gateway')) {
      return 'Server gateway error. Please try again later.';
    }

    if (errorString.contains('http 503') ||
        errorString.contains('service unavailable')) {
      return 'The service is temporarily unavailable. Please try again later.';
    }

    if (errorString.contains('http 504') ||
        errorString.contains('gateway timeout')) {
      return 'The server timed out. Please try again later.';
    }

    // Check for file system errors
    if (errorString.contains('file not found') ||
        errorString.contains('filenotfound')) {
      return 'The audio file was not found on your device.';
    }

    if (errorString.contains('permission denied') ||
        errorString.contains('read-only')) {
      return 'Permission denied. Unable to access or create temporary files.';
    }

    if (errorString.contains('no space') || errorString.contains('disk full')) {
      return 'Insufficient storage space. Please free up some space and try again.';
    }

    // Check for audio format errors
    if (errorString.contains('unsupported format') ||
        errorString.contains('invalid format')) {
      return 'This audio format is not supported. Please use MP3, WAV, OGG, AAC, or M4A files.';
    }

    if (errorString.contains('corrupted') ||
        errorString.contains('malformed')) {
      return 'The audio file appears to be corrupted or incomplete.';
    }

    // Check for network connectivity errors
    if (errorString.contains('no internet') ||
        errorString.contains('network unreachable')) {
      return 'No internet connection. Please check your network and try again.';
    }

    if (errorString.contains('connection failed') ||
        errorString.contains('connection refused')) {
      return 'Failed to connect to the server. Please check your internet connection.';
    }

    // Check for conversion/processing errors
    if (errorString.contains('conversion failed') ||
        errorString.contains('conversion error')) {
      return 'Failed to convert the audio file. The file may be corrupted or in an unsupported format.';
    }

    if (errorString.contains('waveform error') ||
        errorString.contains('waveform failed')) {
      return 'Failed to extract waveform data. The audio file may be corrupted.';
    }

    if (errorString.contains('trim error') ||
        errorString.contains('trim failed')) {
      return 'Failed to trim the audio file. Please check the time range and try again.';
    }

    // Generic fallback message
    return 'An unexpected error occurred: ${_sanitizeErrorMessage(error.toString())}';
  }

  /// Sanitizes error messages to remove technical details that might confuse users
  static String _sanitizeErrorMessage(String message) {
    // Remove common stack trace indicators
    final lines = message.split('\n');
    if (lines.isNotEmpty) {
      message = lines.first;
    }

    // Remove common technical prefixes
    final prefixesToRemove = [
      'Exception: ',
      'Error: ',
      'StateError: ',
      'FileSystemException: ',
      'FormatException: ',
      'TimeoutException: ',
    ];

    for (final prefix in prefixesToRemove) {
      if (message.startsWith(prefix)) {
        message = message.substring(prefix.length);
        break;
      }
    }

    // Limit message length
    if (message.length > 150) {
      message = '${message.substring(0, 147)}...';
    }

    return message;
  }

  /// Checks if an error is recoverable (user can retry)
  static bool isRecoverable(dynamic error) {
    final errorString = error.toString().toLowerCase();

    // Non-recoverable errors
    final nonRecoverablePatterns = [
      'disposed',
      'permission denied',
      'unsupported format',
      'invalid format',
      'file not found',
      'http 400',
      'http 401',
      'http 403',
      'http 404',
    ];

    for (final pattern in nonRecoverablePatterns) {
      if (errorString.contains(pattern)) {
        return false;
      }
    }

    // Recoverable errors (network issues, temporary server problems, etc.)
    return true;
  }

  /// Provides suggested actions for common errors
  static List<String> getSuggestedActions(dynamic error) {
    final errorString = error.toString().toLowerCase();
    final suggestions = <String>[];

    if (errorString.contains('disposed')) {
      suggestions.add('Reload the audio file');
      suggestions.add('Restart the audio player');
    } else if (errorString.contains('timeout') ||
        errorString.contains('network')) {
      suggestions.add('Check your internet connection');
      suggestions.add('Try again in a few moments');
      suggestions.add('Use a different network if available');
    } else if (errorString.contains('permission') ||
        errorString.contains('read-only')) {
      suggestions.add('Check app permissions');
      suggestions.add('Try using a different storage location');
      suggestions.add('Restart the app');
    } else if (errorString.contains('space') ||
        errorString.contains('disk full')) {
      suggestions.add('Free up storage space');
      suggestions.add('Delete unnecessary files');
      suggestions.add('Move files to external storage');
    } else if (errorString.contains('format') ||
        errorString.contains('corrupted')) {
      suggestions.add('Try a different audio file');
      suggestions.add('Ensure the file is not corrupted');
      suggestions.add('Use supported formats: MP3, WAV, OGG, AAC, M4A');
    } else {
      suggestions.add('Try again');
      suggestions.add('Restart the app if the problem persists');
      suggestions.add('Check if the audio file is accessible');
    }

    return suggestions;
  }

  /// Logs error with appropriate level
  static void logError(
    dynamic error, {
    String? context,
    StackTrace? stackTrace,
  }) {
    // Logging can be added here if needed for debugging
    // For production, errors are handled through the getUserFriendlyMessage method
  }
}
