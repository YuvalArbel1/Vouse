// lib/data/repository/auth/x_token_local_repository_impl.dart

import 'package:dio/dio.dart';
import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/domain/entities/secure_db/x_auth_tokens.dart';
import 'package:vouse_flutter/domain/repository/auth/x_token_local_repository.dart';

import '../../data_sources/local/secure_local_database.dart';

/// Implements [XTokenLocalRepository] to manage storing, retrieving,
/// and clearing Twitter (X) OAuth tokens from secure storage.
class XTokenLocalRepositoryImpl implements XTokenLocalRepository {
  final XTokenLocalDataSource _ds;

  /// Expects a [XTokenLocalDataSource] that handles the actual secure storage operations.
  XTokenLocalRepositoryImpl(this._ds);

  /// Writes [tokens] to secure storage, returning [DataSuccess] on success
  /// or [DataFailed] if an error occurs.
  @override
  Future<DataState<void>> saveTokens(XAuthTokens tokens) async {
    try {
      await _ds.storeAccessToken(tokens.accessToken);
      await _ds.storeRefreshToken(tokens.refreshToken);
      return const DataSuccess(null);
    } catch (e) {
      return DataFailed(
        DioException(requestOptions: RequestOptions(path: ''), error: e),
      );
    }
  }

  /// Retrieves stored tokens from secure storage, returning them in a [DataSuccess].
  ///
  /// If both access and refresh tokens are `null`, returns [DataSuccess(null)].
  @override
  Future<DataState<XAuthTokens?>> getTokens() async {
    try {
      final access = await _ds.retrieveAccessToken();
      final refresh = await _ds.retrieveRefreshToken();

      if (access == null && refresh == null) {
        return const DataSuccess(null);
      }

      final tokens = XAuthTokens(
        accessToken: access,
        refreshToken: refresh,
      );
      return DataSuccess(tokens);
    } catch (e) {
      return DataFailed(
        DioException(requestOptions: RequestOptions(path: ''), error: e),
      );
    }
  }

  /// Clears both access and refresh tokens from secure storage.
  @override
  Future<DataState<void>> clearTokens() async {
    try {
      await _ds.clearAll();
      return const DataSuccess(null);
    } catch (e) {
      return DataFailed(
        DioException(requestOptions: RequestOptions(path: ''), error: e),
      );
    }
  }
}
