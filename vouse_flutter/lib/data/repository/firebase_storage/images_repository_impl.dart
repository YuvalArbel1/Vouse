// lib/data/repository/firebase_storage/images_repository_impl.dart

import 'dart:io';
import 'package:flutter/foundation.dart';

import '../../../domain/repository/firebase_storage/images_repository.dart';
import '../../data_sources/remote/firebase_storage/images_remote_data_source.dart';

/// Implements [ImagesRepository] by uploading images to Firebase Storage
/// through [ImagesRemoteDataSource].
class ImagesRepositoryImpl implements ImagesRepository {
  final ImagesRemoteDataSource _dataSource;

  /// Requires an [ImagesRemoteDataSource] to handle the actual uploads.
  ImagesRepositoryImpl(this._dataSource);

  /// Uploads each file in [files] to a user-specific path in Firebase Storage,
  /// returning a list of download URLs.
  @override
  Future<List<String>> uploadImagesToFirebase({
    required String userUid,
    required String postTitle,
    required List<File> files,
  }) async {
    final urls = <String>[];
    for (var i = 0; i < files.length; i++) {
      final downloadUrl = await _dataSource.uploadImage(
        userUid: userUid,
        postTitle: postTitle,
        file: files[i],
        index: i,
      );
      urls.add(downloadUrl);
    }
    return urls;
  }

  /// Deletes images from Firebase Storage using their cloud URLs.
  @override
  Future<void> deleteImagesFromFirebase(List<String> cloudUrls) async {
    for (final url in cloudUrls) {
      try {
        await _dataSource.deleteImageByUrl(url);
      } catch (e) {
        // Log error but continue deleting other images
        if (kDebugMode) {
          print('Error deleting image: $e');
        }
      }
    }
  }

}
