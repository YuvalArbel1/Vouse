import 'dart:io';

import '../../../domain/repository/firebase_storage/images_repository.dart';
import '../../data_sources/remote/firebase_storage/images_remote_data_source.dart';

class ImagesRepositoryImpl implements ImagesRepository {
  final ImagesRemoteDataSource _dataSource;

  ImagesRepositoryImpl(this._dataSource);

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
}
