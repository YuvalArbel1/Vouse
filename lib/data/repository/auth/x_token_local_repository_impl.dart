// data/repository/auth/x_token_local_repository_impl.dart
import 'package:dio/dio.dart';
import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/domain/entities/x_auth_tokens.dart';
import 'package:vouse_flutter/domain/repository/auth/x_token_local_repository.dart';

import '../../data_sources/local/secure_local_database.dart';

class XTokenLocalRepositoryImpl implements XTokenLocalRepository {
  final XTokenLocalDataSource _ds;

  XTokenLocalRepositoryImpl(this._ds);

  @override
  Future<DataState<void>> saveTokens(XAuthTokens tokens) async {
    try {
      await _ds.storeAccessToken(tokens.accessToken);
      await _ds.storeRefreshToken(tokens.refreshToken);
      return const DataSuccess(null);
    } catch (e) {
      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: ''),
          error: e,
        ),
      );
    }
  }

  @override
  Future<DataState<XAuthTokens?>> getTokens() async {
    try {
      final access = await _ds.retrieveAccessToken();
      final refresh = await _ds.retrieveRefreshToken();

      // If both are null, we return null in the DataSuccess
      if (access == null && refresh == null) {
        return const DataSuccess(null);
      }

      // Otherwise, create an XAuthTokens object
      final tokens = XAuthTokens(
        accessToken: access,
        refreshToken: refresh,
      );
      return DataSuccess(tokens);
    } catch (e) {
      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: ''),
          error: e,
        ),
      );
    }
  }

  @override
  Future<DataState<void>> clearTokens() async {
    try {
      await _ds.clearAll();
      return const DataSuccess(null);
    } catch (e) {
      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: ''),
          error: e,
        ),
      );
    }
  }
}
