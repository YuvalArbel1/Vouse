// lib/core/util/image_utils.dart

import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Handles file operations for images, such as moving them to a permanent path.
class ImageUtils {
  /// Copies [imagePaths] to the app’s documents directory and returns the new file paths.
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
}
