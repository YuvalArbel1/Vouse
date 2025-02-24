// lib/presentation/providers/local_db/local_user_providers.dart

import 'package:riverpod/riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:vouse_flutter/data/data_sources/local/user_local_data_source.dart';
import 'package:vouse_flutter/data/repository/local_db/user_local_repository_impl.dart';
import 'package:vouse_flutter/domain/repository/local_db/user_local_repository.dart';
import 'package:vouse_flutter/domain/usecases/home/get_user_usecase.dart';
import 'package:vouse_flutter/domain/usecases/home/save_user_usecase.dart';
import 'database_provider.dart';

/// Creates a [UserLocalDataSource] once the [Database] from [localDatabaseProvider] is initialized.
///
/// Throws an [Exception] if the database is not yet available. In a UI scenario,
/// you may prefer to show a loading screen or handle the async state gracefully.
final userLocalDataSourceProvider = Provider<UserLocalDataSource>((ref) {
  final dbAsyncValue = ref.watch(localDatabaseProvider);

  if (dbAsyncValue.value == null) {
    throw Exception("Database not initialized yet");
  }

  final Database db = dbAsyncValue.value!;
  return UserLocalDataSource(db);
});

/// Creates a [UserLocalRepository] using the above [UserLocalDataSource].
final userLocalRepositoryProvider = Provider<UserLocalRepository>((ref) {
  final ds = ref.watch(userLocalDataSourceProvider);
  return UserLocalRepositoryImpl(ds);
});

/// Provides a [SaveUserUseCase] to insert or update user information in local DB.
final saveUserUseCaseProvider = Provider<SaveUserUseCase>((ref) {
  final repo = ref.watch(userLocalRepositoryProvider);
  return SaveUserUseCase(repo);
});

/// Provides a [GetUserUseCase] to retrieve a user by userId from local DB.
final getUserUseCaseProvider = Provider<GetUserUseCase>((ref) {
  final repo = ref.watch(userLocalRepositoryProvider);
  return GetUserUseCase(repo);
});
