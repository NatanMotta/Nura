import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/models.dart';

/// Handles network operations for downloading audio files
class NetworkService {
  /// Downloads a file from URL with progress tracking
  ///
  /// [url] - URL of the file to download
  /// [outputPath] - Local path where the downloaded file will be saved
  /// [onProgress] - Optional callback for download progress (0.0 to 1.0)
  ///
  /// Throws [Exception] if download fails
  static Future<void> downloadFile(
    String url,
    String outputPath, {
    ProgressCallback? onProgress,
    int maxRetries = 3,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    try {
      final uri = Uri.parse(url);
      final request = http.Request('GET', uri);

      // Add user agent to avoid being blocked by some servers
      request.headers['User-Agent'] = 'Flutter_Audio_Toolkit/1.0';

      final response = await request.send();

      if (response.statusCode != 200) {
        throw Exception('Failed to download file: HTTP ${response.statusCode}');
      }

      // Create directory if it doesn't exist
      final file = File(outputPath);
      final dir = file.parent;
      await dir.create(recursive: true);

      final sink = file.openWrite();
      int downloadedBytes = 0;
      final totalBytes = response.contentLength ?? 0;

      await response.stream
          .listen(
            (List<int> chunk) {
              sink.add(chunk);
              downloadedBytes += chunk.length;

              if (totalBytes > 0 && onProgress != null) {
                final progress = downloadedBytes / totalBytes;
                onProgress(progress.clamp(0.0, 1.0));
              }
            },
            onDone: () async {
              await sink.close();
              onProgress?.call(1.0);
            },
            onError: (error, stackTrace) async {
              await sink.close();
              throw error;
            },
          )
          .asFuture();
    } catch (e) {
      rethrow;
    }
  }

  /// Downloads a file from URL with enhanced error handling and retries
  ///
  /// [url] - URL of the file to download
  /// [outputPath] - Local path where the downloaded file will be saved
  /// [onProgress] - Optional callback for download progress (0.0 to 1.0)
  /// [maxRetries] - Maximum number of retry attempts (default: 3)
  /// [timeout] - Timeout duration for each request (default: 30 seconds)
  ///
  /// Throws [Exception] if download fails after all retries
  static Future<void> downloadFileWithRetry(
    String url,
    String outputPath, {
    ProgressCallback? onProgress,
    int maxRetries = 3,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    Exception? lastException;

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final uri = Uri.parse(url);
        final request = http.Request('GET', uri);

        // Add user agent to avoid being blocked by some servers
        request.headers['User-Agent'] = 'Flutter_Audio_Toolkit/1.0';
        request.headers['Accept'] = '*/*';
        request.headers['Accept-Encoding'] =
            'identity'; // Avoid compression issues

        final response = await request.send().timeout(timeout);

        // Handle different HTTP error codes with user-friendly messages
        if (response.statusCode != 200) {
          String errorMessage = 'HTTP ${response.statusCode}';

          switch (response.statusCode) {
            case 400:
              errorMessage =
                  'Bad Request (HTTP 400) - The server cannot process the request. Please check the URL format.';
              break;
            case 401:
              errorMessage =
                  'Unauthorized (HTTP 401) - Authentication required.';
              break;
            case 403:
              errorMessage =
                  'Forbidden (HTTP 403) - Access denied to this resource.';
              break;
            case 404:
              errorMessage =
                  'Not Found (HTTP 404) - The audio file was not found at this URL.';
              break;
            case 408:
              errorMessage =
                  'Request Timeout (HTTP 408) - The server took too long to respond.';
              break;
            case 429:
              errorMessage =
                  'Too Many Requests (HTTP 429) - Rate limit exceeded. Please try again later.';
              break;
            case 500:
              errorMessage =
                  'Internal Server Error (HTTP 500) - Server encountered an error.';
              break;
            case 502:
              errorMessage =
                  'Bad Gateway (HTTP 502) - Server received invalid response.';
              break;
            case 503:
              errorMessage =
                  'Service Unavailable (HTTP 503) - Server temporarily unavailable.';
              break;
            case 504:
              errorMessage = 'Gateway Timeout (HTTP 504) - Server timeout.';
              break;
            default:
              errorMessage =
                  'Failed to download file: HTTP ${response.statusCode}';
          }

          throw Exception(errorMessage);
        }

        // Create directory if it doesn't exist
        final file = File(outputPath);
        final dir = file.parent;
        await dir.create(recursive: true);

        final sink = file.openWrite();
        int downloadedBytes = 0;
        final totalBytes = response.contentLength ?? 0;

        await response.stream
            .listen(
              (List<int> chunk) {
                sink.add(chunk);
                downloadedBytes += chunk.length;

                if (totalBytes > 0 && onProgress != null) {
                  final progress = downloadedBytes / totalBytes;
                  onProgress(progress.clamp(0.0, 1.0));
                }
              },
              onDone: () async {
                await sink.close();
                onProgress?.call(1.0);
              },
              onError: (error, stackTrace) async {
                await sink.close();
                throw error;
              },
            )
            .asFuture();

        // If we reach here, download was successful
        return;
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());

        if (attempt < maxRetries) {
          // Wait before retrying (exponential backoff)
          final retryDelay = Duration(seconds: attempt * 2);
          await Future.delayed(retryDelay);
        }
      }
    }

    // If all attempts failed, throw the last exception
    throw lastException ??
        Exception('Download failed after $maxRetries attempts');
  }

  /// Validates if a URL is properly formatted
  static bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  /// Extracts filename from URL
  static String? getFilenameFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      if (segments.isNotEmpty) {
        return segments.last;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Checks if the file at the given path exists and is not empty
  static Future<bool> isValidLocalFile(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) return false;
      final stat = await file.stat();
      return stat.size > 0;
    } catch (e) {
      return false;
    }
  }

  /// Cleans up temporary file if it exists
  static Future<void> cleanupFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // Ignore cleanup errors
    }
  }
}
