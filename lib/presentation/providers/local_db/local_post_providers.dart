// lib/presentation/providers/local_db/local_post_providers.dart

import 'package:riverpod/riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:vouse_flutter/data/data_sources/local/post_local_data_source.dart';
import 'package:vouse_flutter/data/repository/local_db/post_local_repository_impl.dart';
import 'package:vouse_flutter/domain/repository/local_db/post_local_repository.dart';

import 'package:vouse_flutter/domain/usecases/post/save_post_usecase.dart';
import 'package:vouse_flutter/domain/usecases/post/get_single_post_usecase.dart';
import 'package:vouse_flutter/domain/usecases/post/get_posts_by_user_usecase.dart';
import 'package:vouse_flutter/domain/usecases/post/delete_post_usecase.dart';

import 'database_provider.dart';

/// Builds a [PostLocalDataSource] once the [Database] from [localDatabaseProvider] is ready.
///
/// If the DB is still loading, we throw an [Exception]. In a real UI,
/// you might handle loading states more gracefully.
final postLocalDataSourceProvider = Provider<PostLocalDataSource>((ref) {
  final dbAsyncValue = ref.watch(localDatabaseProvider);
  if (dbAsyncValue.value == null) {
    throw Exception("Database not initialized yet");
  }
  final Database db = dbAsyncValue.value!;
  return PostLocalDataSource(db);
});

/// Creates a [PostLocalRepository] using the [PostLocalDataSource].
final postLocalRepositoryProvider = Provider<PostLocalRepository>((ref) {
  final ds = ref.watch(postLocalDataSourceProvider);
  return PostLocalRepositoryImpl(ds);
});

/// Provides the [SavePostUseCase] to insert or update posts in local DB.
final savePostUseCaseProvider = Provider<SavePostUseCase>((ref) {
  final repo = ref.watch(postLocalRepositoryProvider);
  return SavePostUseCase(repo);
});

/// Provides the [GetSinglePostUseCase] for retrieving a post by its local ID.
final getSinglePostUseCaseProvider = Provider<GetSinglePostUseCase>((ref) {
  final repo = ref.watch(postLocalRepositoryProvider);
  return GetSinglePostUseCase(repo);
});

/// Provides the [GetPostsByUserUseCase] for fetching all posts owned by a specific user.
final getPostsByUserUseCaseProvider = Provider<GetPostsByUserUseCase>((ref) {
  final repo = ref.watch(postLocalRepositoryProvider);
  return GetPostsByUserUseCase(repo);
});

/// Provides the [DeletePostUseCase] for removing a specific post by its local ID.
final deletePostUseCaseProvider = Provider<DeletePostUseCase>((ref) {
  final repo = ref.watch(postLocalRepositoryProvider);
  return DeletePostUseCase(repo);
});
