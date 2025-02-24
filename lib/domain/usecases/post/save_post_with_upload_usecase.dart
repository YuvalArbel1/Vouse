// lib/domain/usecases/post/save_post_with_upload_usecase.dart

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/core/usecases/usecase.dart';

import '../../entities/local_db/post_entity.dart';
import '../../repository/firebase_storage/images_repository.dart';
import '../../repository/local_db/post_local_repository.dart';

/// Holds data required to save a post and upload its images.
class SavePostWithUploadParams {
  final String userUid;
  final PostEntity postEntity;
  final List<File> localImageFiles;

  /// Combines [userUid], a [postEntity] to be saved, and [localImageFiles]
  /// that need to be uploaded before saving.
  SavePostWithUploadParams({
    required this.userUid,
    required this.postEntity,
    required this.localImageFiles,
  });
}

/// A use case that uploads images to remote storage, then saves the post locally.
///
/// 1) Uploads images to [ImagesRepository].
/// 2) Copies the returned URLs into [postEntity].
/// 3) Saves the updated post via [PostLocalRepository].
class SavePostWithUploadUseCase
    extends UseCase<DataState<void>, SavePostWithUploadParams> {
  final PostLocalRepository _postLocalRepo;
  final ImagesRepository _imagesRepo;

  /// Expects both a local post repository and an images repository for uploading.
  SavePostWithUploadUseCase(this._postLocalRepo, this._imagesRepo);

  @override
  Future<DataState<void>> call({SavePostWithUploadParams? params}) async {
    if (params == null) {
      return DataFailed(
        DioException(
          error: 'Params cannot be null',
          requestOptions: RequestOptions(path: ''),
        ),
      );
    }

    try {
      // 1) Upload images to Firebase
      final cloudUrls = await _imagesRepo.uploadImagesToFirebase(
        userUid: params.userUid,
        postTitle: params.postEntity.title,
        files: params.localImageFiles,
      );

      // 2) Create a new PostEntity with the uploaded URLs
      final finalPost = params.postEntity.copyWith(
        cloudImageUrls: cloudUrls,
        // Possibly set updatedAt = now, if desired
      );

      // 3) Save final post to local DB
      await _postLocalRepo.savePost(finalPost, params.userUid);

      return const DataSuccess(null);
    } catch (e) {
      return DataFailed(
        DioException(
          error: 'Error saving post with upload: $e',
          requestOptions: RequestOptions(path: ''),
        ),
      );
    }
  }
}
