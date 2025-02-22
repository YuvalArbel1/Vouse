import 'package:riverpod/riverpod.dart';
import 'package:vouse_flutter/data/data_sources/local/post_local_data_source.dart';
import 'package:vouse_flutter/data/repository/local_db/post_local_repository_impl.dart';

import '../../../domain/repository/local_db/post_local_repository.dart';
import '../../../domain/usecases/post/delete_post_usecase.dart';
import '../../../domain/usecases/post/get_posts_by_user_usecase.dart';
import '../../../domain/usecases/post/get_single_post_usecase.dart';
import '../../../domain/usecases/post/save_post_usecase.dart';
import '../home/local_user_providers.dart';


/// Provide the PostLocalDataSource
final postLocalDataSourceProvider = Provider<PostLocalDataSource>((ref) {
  final userDS = ref.watch(userLocalDataSourceProvider);
  return PostLocalDataSource(userDS);
});

/// Provide the PostLocalRepository
final postLocalRepositoryProvider = Provider<PostLocalRepository>((ref) {
  final ds = ref.watch(postLocalDataSourceProvider);
  return PostLocalRepositoryImpl(ds);
});

/// Provide the SavePostUseCase
final savePostUseCaseProvider = Provider<SavePostUseCase>((ref) {
  final repo = ref.watch(postLocalRepositoryProvider);
  return SavePostUseCase(repo);
});

/// Provide the GetPostsByUserUseCase
final getPostsByUserUseCaseProvider = Provider<GetPostsByUserUseCase>((ref) {
  final repo = ref.watch(postLocalRepositoryProvider);
  return GetPostsByUserUseCase(repo);
});

/// Provide the GetSinglePostUseCase
final getSinglePostUseCaseProvider = Provider<GetSinglePostUseCase>((ref) {
  final repo = ref.watch(postLocalRepositoryProvider);
  return GetSinglePostUseCase(repo);
});

/// Provide the DeletePostUseCase
final deletePostUseCaseProvider = Provider<DeletePostUseCase>((ref) {
  final repo = ref.watch(postLocalRepositoryProvider);
  return DeletePostUseCase(repo);
});
