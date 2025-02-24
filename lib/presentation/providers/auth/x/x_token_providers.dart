// lib/presentation/providers/auth/x/x_token_providers.dart

import 'package:riverpod/riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:vouse_flutter/domain/repository/auth/x_token_local_repository.dart';
import '../../../../data/data_sources/local/secure_local_database.dart';
import '../../../../data/repository/auth/x_token_local_repository_impl.dart';
import '../../../../domain/usecases/auth/x/clear_x_tokens_usecase.dart';
import '../../../../domain/usecases/auth/x/get_x_tokens_usecase.dart';
import '../../../../domain/usecases/auth/x/save_x_tokens_usecase.dart';

/// Provides a single [FlutterSecureStorage] instance for storing secure key-value pairs.
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

/// Supplies an [XTokenLocalDataSource] that interacts with [FlutterSecureStorage].
final xTokenLocalDataSourceProvider = Provider<XTokenLocalDataSource>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  return XTokenLocalDataSource(secureStorage);
});

/// Implements [XTokenLocalRepository] using [XTokenLocalDataSource].
final xTokenLocalRepositoryProvider = Provider<XTokenLocalRepository>((ref) {
  final ds = ref.watch(xTokenLocalDataSourceProvider);
  return XTokenLocalRepositoryImpl(ds);
});

/// Provides a [SaveXTokensUseCase] to store Twitter (X) tokens locally.
final saveXTokensUseCaseProvider = Provider<SaveXTokensUseCase>((ref) {
  final repo = ref.watch(xTokenLocalRepositoryProvider);
  return SaveXTokensUseCase(repo);
});

/// Provides a [GetXTokensUseCase] to retrieve stored Twitter (X) tokens.
final getXTokensUseCaseProvider = Provider<GetXTokensUseCase>((ref) {
  final repo = ref.watch(xTokenLocalRepositoryProvider);
  return GetXTokensUseCase(repo);
});

/// Provides a [ClearXTokensUseCase] to remove stored Twitter (X) tokens from secure storage.
final clearXTokensUseCaseProvider = Provider<ClearXTokensUseCase>((ref) {
  final repo = ref.watch(xTokenLocalRepositoryProvider);
  return ClearXTokensUseCase(repo);
});
