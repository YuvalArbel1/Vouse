// lib/data/repository/x_auth_repository_impl.dart

import 'package:dio/dio.dart';
import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/domain/repository/auth/x_auth_repository.dart';
import 'package:vouse_flutter/data/clients/twitter_oauth2_client.dart';

import '../../../domain/entities/x_auth_tokens.dart';

class XAuthRepositoryImpl implements XAuthRepository {
  final TwitterOAuth2Client _client;

  XAuthRepositoryImpl(this._client);

  @override
  Future<DataState<XAuthTokens>> signInToX() async {
    try {
      // Request offline access for refresh token
      final tokens = await _client.login(scopes: [
        'tweet.read',
        'users.read',
        'tweet.write',
        'offline.access',
      ]);

      if (tokens.accessToken == null) {
        return DataFailed(
          DioException(
            requestOptions: RequestOptions(path: ''),
            error: 'No access token returned from Twitter.',
          ),
        );
      }

      // Return both tokens inside DataSuccess
      return DataSuccess(tokens);

    } catch (e) {
      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: ''),
          error: e.toString(),
        ),
      );
    }
  }
}
