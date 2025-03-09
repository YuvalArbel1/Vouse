// lib/data/repository/x_auth_repository_impl.dart

import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart'; // For potential PlatformExceptions from OAuth
import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/data/clients/twitter/twitter_oauth2_client.dart';
import 'package:vouse_flutter/domain/entities/secure_db/x_auth_tokens.dart';
import 'package:vouse_flutter/domain/repository/auth/x_auth_repository.dart';

/// Implements X (Twitter) OAuth2 sign-in flows via [TwitterOAuth2Client].
///
/// Returns user-friendly error messages for common OAuth errors.
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
        'like.read',
      ]);

      // If no access token is returned, treat it as an error
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
      // Provide user-friendly errors for known codes, fallback otherwise
      final errorMsg = _mapTwitterOAuthError(e);
      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: ''),
          error: errorMsg,
        ),
      );
    }
  }

  /// Maps known OAuth or PlatformException errors to user-friendly messages.
  /// Returns the original [e.toString()] if we can't match a known case.
  String _mapTwitterOAuthError(dynamic error) {
    // The client may throw a PlatformException if user cancels or config is invalid
    if (error is PlatformException) {
      switch (error.code) {
        case 'user_cancelled':
        case 'CANCELED':
          return 'Twitter sign-in was cancelled by the user.';
        case 'invalid_clientId':
          return 'Invalid Twitter client configuration. Please contact support.';
        case 'invalid_configuration':
          return 'Twitter OAuth configuration is invalid. Please verify setup.';
        default:
          return error.message ??
              'An unknown error occurred during Twitter sign-in.';
      }
    }

    // If it's not a recognized exception type, just return string
    return error.toString();
  }
}
