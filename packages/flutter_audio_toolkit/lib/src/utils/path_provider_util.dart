import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Utility for handling file paths across different platforms
class PathProviderUtil {
  /// Gets an appropriate temporary directory path for the current platform
  static Future<String> getTempDirectoryPath() async {
    try {
      if (kIsWeb) {
        // For web, use a simple temp path
        return '/tmp';
      }

      // Use path_provider for proper cross-platform temp directory
      try {
        final tempDir = await getTemporaryDirectory();
        return tempDir.path;
      } catch (e) {
        // path_provider failed, continue to fallback
      }

      // Fallback to system temp directory
      final systemTempDir = Directory.systemTemp;
      if (await systemTempDir.exists()) {
        // Test if we can write to it
        try {
          final testFile = File(
            '${systemTempDir.path}/flutter_audio_toolkit_test_${DateTime.now().millisecondsSinceEpoch}',
          );
          await testFile.writeAsString('test');
          await testFile.delete();
          return systemTempDir.path;
        } catch (e) {
          // System temp directory not writable, continue to fallback
        }
      }

      // Fallback to platform-specific paths
      if (Platform.isAndroid || Platform.isLinux) {
        // Try Android/Linux specific paths
        final candidates = [
          '/tmp',
          '/data/local/tmp',
          '/storage/emulated/0/Android/data/cache',
        ];

        for (final path in candidates) {
          try {
            final dir = Directory(path);
            if (await dir.exists()) {
              // Test if we can write to it
              final testFile = File(
                '$path/flutter_audio_toolkit_test_${DateTime.now().millisecondsSinceEpoch}',
              );
              await testFile.writeAsString('test');
              await testFile.delete();
              return path;
            }
          } catch (e) {
            continue;
          }
        }
      }

      // Last resort: current directory
      return Directory.current.path;
    } catch (e) {
      return Directory.current.path;
    }
  }

  /// Gets an appropriate app documents directory path
  static Future<String> getAppDocumentsPath() async {
    try {
      if (kIsWeb) {
        return '/documents';
      }

      // Use path_provider for proper cross-platform documents directory
      try {
        final documentsDir = await getApplicationDocumentsDirectory();
        return documentsDir.path;
      } catch (e) {
        // path_provider documents directory failed, try alternatives
      }

      // Try to use alternative app-specific directories
      try {
        if (Platform.isAndroid) {
          // Try external storage directory first
          final externalDir = await getExternalStorageDirectory();
          if (externalDir != null) {
            return externalDir.path;
          }
        }

        // Try application support directory
        final appSupportDir = await getApplicationSupportDirectory();
        return appSupportDir.path;
      } catch (e) {
        // Alternative directories failed, use manual fallback
      }

      // Manual fallback for platforms
      if (Platform.isAndroid) {
        // Android external storage documents
        final candidates = [
          '/storage/emulated/0/Documents',
          '/storage/emulated/0/Download',
          '/sdcard/Documents',
          '/sdcard/Download',
        ];

        for (final path in candidates) {
          try {
            final dir = Directory(path);
            if (await dir.exists()) {
              return path;
            }
          } catch (e) {
            continue;
          }
        }
      } else if (Platform.isIOS) {
        // For iOS, fallback to a reasonable path
        return '/var/mobile/Documents';
      }

      // Fallback to current directory
      return Directory.current.path;
    } catch (e) {
      return Directory.current.path;
    }
  }

  /// Creates a safe temporary file path for audio downloads
  /// Falls back to app documents if temp directory is not writable
  static Future<String> createTempFilePath({
    String? prefix,
    String? suffix,
    String? playerId,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final actualPrefix = prefix ?? 'flutter_audio_toolkit';
    final actualSuffix = suffix ?? '.tmp';
    final playerIdPart = playerId != null ? '_$playerId' : '';
    final filename = '$actualPrefix${playerIdPart}_$timestamp$actualSuffix';

    // First try temp directory
    try {
      final tempPath = await getTempDirectoryPath();
      final tempFile = '$tempPath/$filename';

      // Test if we can create files in temp directory
      final testDir = Directory(tempPath);
      if (!await testDir.exists()) {
        await testDir.create(recursive: true);
      }

      // Test write permission
      final file = File(tempFile);
      await file.writeAsString('test');
      await file.delete();

      return tempFile;
    } catch (e) {
      // Fallback to app documents directory
      try {
        final docsPath = await getAppDocumentsPath();
        final docsDir = Directory('$docsPath/temp');
        if (!await docsDir.exists()) {
          await docsDir.create(recursive: true);
        }
        return '${docsDir.path}/$filename';
      } catch (e2) {
        // Last resort: current directory
        return './$filename';
      }
    }
  }

  /// Ensures a directory exists, creating it if necessary
  static Future<void> ensureDirectoryExists(String path) async {
    try {
      final dir = Directory(path);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Cleans up a file safely, ignoring errors
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

  /// Validates that a file path is writable
  static Future<bool> isPathWritable(String path) async {
    try {
      final dir = Directory(path).parent;
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      final testFile = File('$path.test');
      await testFile.writeAsString('test');
      await testFile.delete();
      return true;
    } catch (e) {
      return false;
    }
  }
}
