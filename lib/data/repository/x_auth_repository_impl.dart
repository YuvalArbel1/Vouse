import 'package:dio/dio.dart';
import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/domain/repository/auth/x_auth_repository.dart';
import 'package:vouse_flutter/data/clients/twitter_oauth2_client.dart';

class XAuthRepositoryImpl implements XAuthRepository {
  final TwitterOAuth2Client _client;

  XAuthRepositoryImpl(this._client);

  @override
  Future<DataState<String>> signInToX() async {
    try {
      // Request login with read scopes. If you have a plan that allows tweet.write, add it.
      final token = await _client.login(scopes: [
        'tweet.read',
        'users.read',
        'tweet.write',
      ]);

      if (token == null) {
        return DataFailed(
          DioException(
            requestOptions: RequestOptions(path: ''),
            error: 'No access token returned from Twitter.',
          ),
        );
      }

      return DataSuccess(token);
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
