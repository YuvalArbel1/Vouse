import 'package:riverpod/riverpod.dart';
import 'package:vouse_flutter/data/repository/user_local_repository_impl.dart';

import '../../../data/data_sources/local.dart';
import '../../../domain/repository/home/user_local_repository.dart';
import '../../../domain/usecases/home/get_user_usecase.dart';
import '../../../domain/usecases/home/save_user_usecase.dart';

/// Provide the local data source
final userLocalDataSourceProvider = Provider<UserLocalDataSource>((ref) {
  return UserLocalDataSource();
});

/// Provide the UserLocalRepository
final userLocalRepositoryProvider = Provider<UserLocalRepository>((ref) {
  final ds = ref.watch(userLocalDataSourceProvider);
  return UserLocalRepositoryImpl(ds);
});

/// Provide the SaveUserUseCase
final saveUserUseCaseProvider = Provider<SaveUserUseCase>((ref) {
  final repo = ref.watch(userLocalRepositoryProvider);
  return SaveUserUseCase(repo);
});

/// Provide the GetUserUseCase
final getUserUseCaseProvider = Provider<GetUserUseCase>((ref) {
  final repo = ref.watch(userLocalRepositoryProvider);
  return GetUserUseCase(repo);
});
