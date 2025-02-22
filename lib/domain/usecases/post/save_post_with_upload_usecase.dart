// domain/usecases/post/publish_post_usecase.dart

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/core/usecases/usecase.dart';
import 'package:vouse_flutter/domain/entities/locaal db/post_entity.dart';

import '../../repository/firebase_storage/images_repository.dart';
import '../../repository/local_db/post_local_repository.dart';

class SavePostWithUploadParams {
  final String userUid;
  final PostEntity postEntity;
  final List<File> localImageFiles;

  // local copies that we want to upload
  // possibly including the ones in the documents path.

  SavePostWithUploadParams({
    required this.userUid,
    required this.postEntity,
    required this.localImageFiles,
  });
}

class SavePostWithUploadUseCase
    extends UseCase<DataState<void>, SavePostWithUploadParams> {
  final PostLocalRepository _postLocalRepo;
  final ImagesRepository _imagesRepo;

  SavePostWithUploadUseCase(this._postLocalRepo, this._imagesRepo);

  @override
  Future<DataState<void>> call({SavePostWithUploadParams? params}) async {
    if (params == null) {
      // error
      return DataFailed(DioException(
          error: 'Params cannot be null',
          requestOptions: RequestOptions(path: '')));
    }

    try {
      // 1) Upload images
      final cloudUrls = await _imagesRepo.uploadImagesToFirebase(
        userUid: params.userUid,
        postTitle: params.postEntity.title,
        // be sure you sanitize or handle spaces
        files: params.localImageFiles,
      );

      // 2) Merge those cloud URLs into the post entity
      final finalPost = params.postEntity.copyWith(
        cloudImageUrls: cloudUrls,
        // Possibly updatedAt = now, etc.
      );

      // 3) Save the post to local DB
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
