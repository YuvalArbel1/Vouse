import 'package:riverpod/riverpod.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:vouse_flutter/data/data_sources/remote/firebase_storage/images_remote_data_source.dart';
import 'package:vouse_flutter/data/repository/firebase_storage/images_repository_impl.dart';
import 'package:vouse_flutter/domain/repository/firebase_storage/images_repository.dart';
import 'package:vouse_flutter/domain/usecases/post/save_post_with_upload_usecase.dart';

import '../local_db/local_post_providers.dart'; // For postLocalRepositoryProvider

/// 1) Provide a FirebaseStorage instance.
final firebaseStorageProvider = Provider<FirebaseStorage>((ref) {
  return FirebaseStorage.instance;
});

/// 2) Provide ImagesRemoteDataSource (which uploads to Firebase).
final imagesRemoteDataSourceProvider = Provider<ImagesRemoteDataSource>((ref) {
  final storage = ref.watch(firebaseStorageProvider);
  return ImagesRemoteDataSource(storage: storage);
});

/// 3) Provide the ImagesRepository (uses ImagesRemoteDataSource).
final imagesRepositoryProvider = Provider<ImagesRepository>((ref) {
  final remoteDS = ref.watch(imagesRemoteDataSourceProvider);
  return ImagesRepositoryImpl(remoteDS);
});

/// 4) Provide SavePostWithUploadUseCase (requires local post repo + images repo).
final savePostWithUploadUseCaseProvider =
Provider<SavePostWithUploadUseCase>((ref) {
  final postRepo = ref.watch(postLocalRepositoryProvider);
  final imagesRepo = ref.watch(imagesRepositoryProvider);
  return SavePostWithUploadUseCase(postRepo, imagesRepo);
});
