// lib/presentation/providers/post/post_local_providers.dart

import 'package:riverpod/riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:vouse_flutter/data/data_sources/local/post_local_data_source.dart';
import 'package:vouse_flutter/data/repository/local_db/post_local_repository_impl.dart';
import 'package:vouse_flutter/domain/repository/local_db/post_local_repository.dart';
import 'package:vouse_flutter/domain/usecases/post/save_post_usecase.dart';
import 'package:vouse_flutter/domain/usecases/post/get_single_post_usecase.dart';
import 'package:vouse_flutter/domain/usecases/post/get_posts_by_user_usecase.dart';
import 'package:vouse_flutter/domain/usecases/post/delete_post_usecase.dart';

import '../local_db/database_provider.dart';

/// Provides a [PostLocalDataSource], creating it once the database is ready.
final postLocalDataSourceProvider = Provider<PostLocalDataSource>((ref) {
  final dbAsyncValue = ref.watch(localDatabaseProvider);

  // If the database hasn't loaded yet, you can throw or handle a loading state here.
  if (dbAsyncValue.value == null) {
    throw Exception("Database not initialized yet.");
  }

  final Database db = dbAsyncValue.value!;
  return PostLocalDataSource(db);
});

/// Provides a [PostLocalRepository] using the [PostLocalDataSource].
final postLocalRepositoryProvider = Provider<PostLocalRepository>((ref) {
  final ds = ref.watch(postLocalDataSourceProvider);
  return PostLocalRepositoryImpl(ds);
});

/// Provides the [SavePostUseCase].
final savePostUseCaseProvider = Provider<SavePostUseCase>((ref) {
  final repo = ref.watch(postLocalRepositoryProvider);
  return SavePostUseCase(repo);
});

/// Provides the [GetSinglePostUseCase].
final getSinglePostUseCaseProvider = Provider<GetSinglePostUseCase>((ref) {
  final repo = ref.watch(postLocalRepositoryProvider);
  return GetSinglePostUseCase(repo);
});

/// Provides the [GetPostsByUserUseCase].
final getPostsByUserUseCaseProvider = Provider<GetPostsByUserUseCase>((ref) {
  final repo = ref.watch(postLocalRepositoryProvider);
  return GetPostsByUserUseCase(repo);
});

/// Provides the [DeletePostUseCase].
final deletePostUseCaseProvider = Provider<DeletePostUseCase>((ref) {
  final repo = ref.watch(postLocalRepositoryProvider);
  return DeletePostUseCase(repo);
});
