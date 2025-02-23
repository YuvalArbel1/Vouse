// lib/presentation/providers/local_db/local_user_providers.dart

import 'package:riverpod/riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:vouse_flutter/data/data_sources/local/user_local_data_source.dart';
import 'package:vouse_flutter/data/repository/local_db/user_local_repository_impl.dart';
import 'package:vouse_flutter/domain/repository/local_db/user_local_repository.dart';
import 'package:vouse_flutter/domain/usecases/home/get_user_usecase.dart';
import 'package:vouse_flutter/domain/usecases/home/save_user_usecase.dart';

import 'database_provider.dart';

/// Creates a [UserLocalDataSource] by retrieving the [Database] from [localDatabaseProvider].
final userLocalDataSourceProvider = Provider<UserLocalDataSource>((ref) {
  final dbAsyncValue = ref.watch(localDatabaseProvider);

  // If the database isn't ready yet, you can throw or handle loading states.
  if (dbAsyncValue.value == null) {
    throw Exception("Database not initialized yet");
  }

  final Database db = dbAsyncValue.value!;
  return UserLocalDataSource(db);
});

/// Creates a [UserLocalRepository] using the [UserLocalDataSource].
final userLocalRepositoryProvider = Provider<UserLocalRepository>((ref) {
  final ds = ref.watch(userLocalDataSourceProvider);
  return UserLocalRepositoryImpl(ds);
});

/// UseCase provider: SaveUserUseCase
final saveUserUseCaseProvider = Provider<SaveUserUseCase>((ref) {
  final repo = ref.watch(userLocalRepositoryProvider);
  return SaveUserUseCase(repo);
});

/// UseCase provider: GetUserUseCase
final getUserUseCaseProvider = Provider<GetUserUseCase>((ref) {
  final repo = ref.watch(userLocalRepositoryProvider);
  return GetUserUseCase(repo);
});
