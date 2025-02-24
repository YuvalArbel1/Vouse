// lib/domain/repository/firebase_storage/images_repository.dart

import 'dart:io';

/// A contract for uploading images to a remote storage (e.g., Firebase Storage).
abstract class ImagesRepository {
  /// Uploads the given [files] to remote storage under:
  ///   userUid/postTitle/< uniqueFileName >.< ext >
  ///
  /// Returns a list of download URLs for each uploaded file.
  Future<List<String>> uploadImagesToFirebase({
    required String userUid,
    required String postTitle,
    required List<File> files,
  });
}
