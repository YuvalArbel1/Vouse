// lib/presentation/providers/post/save_post_with_upload_provider.dart

import 'package:riverpod/riverpod.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:vouse_flutter/data/data_sources/remote/firebase_storage/images_remote_data_source.dart';
import 'package:vouse_flutter/data/repository/firebase_storage/images_repository_impl.dart';
import 'package:vouse_flutter/domain/repository/firebase_storage/images_repository.dart';
import 'package:vouse_flutter/domain/usecases/post/save_post_with_upload_usecase.dart';
import '../local_db/local_post_providers.dart'; // For postLocalRepositoryProvider

/// Provides a [FirebaseStorage] instance for image uploads.
final firebaseStorageProvider = Provider<FirebaseStorage>((ref) {
  return FirebaseStorage.instance;
});

/// Creates an [ImagesRemoteDataSource] for interacting with Firebase Storage.
final imagesRemoteDataSourceProvider = Provider<ImagesRemoteDataSource>((ref) {
  final storage = ref.watch(firebaseStorageProvider);
  return ImagesRemoteDataSource(storage: storage);
});

/// Builds an [ImagesRepository] that uses [ImagesRemoteDataSource].
final imagesRepositoryProvider = Provider<ImagesRepository>((ref) {
  final remoteDS = ref.watch(imagesRemoteDataSourceProvider);
  return ImagesRepositoryImpl(remoteDS);
});

/// Constructs a [SavePostWithUploadUseCase], combining post local DB logic
/// and image upload functionality into a single action.
final savePostWithUploadUseCaseProvider =
    Provider<SavePostWithUploadUseCase>((ref) {
  final postRepo = ref.watch(postLocalRepositoryProvider);
  final imagesRepo = ref.watch(imagesRepositoryProvider);
  return SavePostWithUploadUseCase(postRepo, imagesRepo);
});
