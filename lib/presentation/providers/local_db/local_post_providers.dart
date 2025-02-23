// lib/presentation/providers/local_db/local_post_providers.dart

import 'package:riverpod/riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:vouse_flutter/data/data_sources/local/post_local_data_source.dart';
import 'package:vouse_flutter/data/repository/local_db/post_local_repository_impl.dart';
import 'package:vouse_flutter/domain/repository/local_db/post_local_repository.dart';
// If you have post usecases, import them too:
// import 'package:vouse_flutter/domain/usecases/post/...';

import 'database_provider.dart';

/// Creates a [PostLocalDataSource] by retrieving the [Database] from [localDatabaseProvider].
final postLocalDataSourceProvider = Provider<PostLocalDataSource>((ref) {
  final dbAsyncValue = ref.watch(localDatabaseProvider);
  if (dbAsyncValue.value == null) {
    throw Exception("Database not initialized yet");
  }
  final Database db = dbAsyncValue.value!;
  return PostLocalDataSource(db);
});

/// Creates a [PostLocalRepository] using [PostLocalDataSource].
final postLocalRepositoryProvider = Provider<PostLocalRepository>((ref) {
  final ds = ref.watch(postLocalDataSourceProvider);
  return PostLocalRepositoryImpl(ds);
});

// If you have post-specific usecases, define providers for them here:
// final savePostUseCaseProvider = Provider<SavePostUseCase>((ref) {
//   final repo = ref.watch(postLocalRepositoryProvider);
//   return SavePostUseCase(repo);
// });
