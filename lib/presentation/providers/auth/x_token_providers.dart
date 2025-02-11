import 'package:riverpod/riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:vouse_flutter/domain/repository/auth/x_token_local_repository.dart';

import '../../../data/data_sources/local/secure_local_database.dart';
import '../../../data/repository/auth/x_token_local_repository_impl.dart';
import '../../../domain/usecases/auth/x/clear_x_tokens_usecase.dart';
import '../../../domain/usecases/auth/x/get_x_tokens_usecase.dart';
import '../../../domain/usecases/auth/x/save_x_tokens_usecase.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final xTokenLocalDataSourceProvider = Provider<XTokenLocalDataSource>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  return XTokenLocalDataSource(secureStorage);
});

final xTokenLocalRepositoryProvider = Provider<XTokenLocalRepository>((ref) {
  final ds = ref.watch(xTokenLocalDataSourceProvider);
  return XTokenLocalRepositoryImpl(ds);
});

final saveXTokensUseCaseProvider = Provider<SaveXTokensUseCase>((ref) {
  final repo = ref.watch(xTokenLocalRepositoryProvider);
  return SaveXTokensUseCase(repo);
});

final getXTokensUseCaseProvider = Provider<GetXTokensUseCase>((ref) {
  final repo = ref.watch(xTokenLocalRepositoryProvider);
  return GetXTokensUseCase(repo);
});

final clearXTokensUseCaseProvider = Provider<ClearXTokensUseCase>((ref) {
  final repo = ref.watch(xTokenLocalRepositoryProvider);
  return ClearXTokensUseCase(repo);
});
