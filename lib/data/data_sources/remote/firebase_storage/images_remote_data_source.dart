// data/remote/images_remote_data_source.dart

import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class ImagesRemoteDataSource {
  final FirebaseStorage _storage;

  ImagesRemoteDataSource({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  /// Upload a single image file to Storage under a path like:
  ///   userUid/postTitle/<uniqueFileName>.jpg
  /// Returns the download URL.
  Future<String> uploadImage({
    required String userUid,
    required String postTitle,
    required File file,
    required int index,
  }) async {
    final fileName = '${postTitle}_img_$index.jpg';
    final ref = _storage
        .ref()
        .child(userUid)
        .child(postTitle)
        .child(fileName);

    final uploadTask = ref.putFile(file);

    final snapshot = await uploadTask.whenComplete(() => {});
    final downloadUrl = await snapshot.ref.getDownloadURL();
    return downloadUrl;
  }
}
