// lib/core/util/image_utils.dart

import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Handles file operations for images, such as moving them to a permanent path.
///
class ImageUtils {
  /// Copies [imagePaths] to the app's documents directory and returns the new file paths.
  static Future<List<String>> moveImagesToPermanentFolder(List<String> imagePaths) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dirPath = docsDir.path;
    final newPaths = <String>[];

    for (final originalPath in imagePaths) {
      final fileName = p.basename(originalPath);
      final newPath = p.join(dirPath, fileName);
      final newFile = await File(originalPath).copy(newPath);
      newPaths.add(newFile.path);
    }
    return newPaths;
  }

  /// Copies [singleImagePath] to a stable/permanent folder in the app's documents directory,
  /// returning the new absolute path. If the same image is chosen again (and has the same
  /// file name), this method should return the same final path, helping identify duplicates.
  static Future<String> copySingleImageToPermanentFolder(String singleImagePath) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dirPath = docsDir.path;

    // Extract the file name from the ephemeral path.
    final fileName = p.basename(singleImagePath);

    // Build a final path in the app's docs folder.
    // If the same fileName is used, it helps deduplicate.
    final newPath = p.join(dirPath, fileName);

    // Actually copy the file from ephemeral location to the stable path.
    final newFile = await File(singleImagePath).copy(newPath);
    return newFile.path;
  }
}
