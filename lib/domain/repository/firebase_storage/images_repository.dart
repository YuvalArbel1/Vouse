import 'dart:io';

abstract class ImagesRepository {
  Future<List<String>> uploadImagesToFirebase({
    required String userUid,
    required String postTitle,
    required List<File> files,
  });
}
