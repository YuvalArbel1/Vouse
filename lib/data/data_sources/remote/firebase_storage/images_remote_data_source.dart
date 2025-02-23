// lib/data/remote/images_remote_data_source.dart

import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

/// Provides methods to upload images to Firebase Storage.
class ImagesRemoteDataSource {
  final FirebaseStorage _storage;

  /// If [storage] is not provided, this defaults to [FirebaseStorage.instance].
  ImagesRemoteDataSource({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  /// Uploads [file] to Firebase Storage at a path:
  ///   userUid/postTitle/index.jpg
  ///
  /// Returns the resulting download URL.
  Future<String> uploadImage({
    required String userUid,
    required String postTitle,
    required File file,
    required int index,
  }) async {
    final fileName = '${postTitle}_img_$index.jpg';
    final ref = _storage.ref().child(userUid).child(postTitle).child(fileName);

    final uploadTask = ref.putFile(file);
    final snapshot = await uploadTask.whenComplete(() => {});
    return snapshot.ref.getDownloadURL();
  }
}
