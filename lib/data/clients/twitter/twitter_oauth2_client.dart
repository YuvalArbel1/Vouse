// lib/data/clients/twitter/twitter_oauth2_client.dart

import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:vouse_flutter/domain/entities/secure_db/x_auth_tokens.dart';

/// A client that manages Twitter (X) OAuth2 authentication flows using PKCE.
///
/// Relies on [FlutterAppAuth] to handle the authorization code exchange and retrieve
/// access/refresh tokens for the user.
class TwitterOAuth2Client {
  final FlutterAppAuth appAuth;
  final String clientId;
  final String redirectUrl;

  /// Constructs a [TwitterOAuth2Client] with the given [appAuth], [clientId], and [redirectUrl].
  TwitterOAuth2Client({
    required this.appAuth,
    required this.clientId,
    required this.redirectUrl,
  });

  /// Initiates OAuth2 with PKCE, returning both [XAuthTokens] if successful.
  ///
  /// You must have 'offline.access' in [scopes] to receive a refresh token.
  ///
  /// Throws if authorization fails or if [FlutterAppAuth] encounters an error.
  Future<XAuthTokens> login({required List<String> scopes}) async {
    final serviceConfig = const AuthorizationServiceConfiguration(
      authorizationEndpoint: 'https://twitter.com/i/oauth2/authorize',
      tokenEndpoint: 'https://api.twitter.com/2/oauth2/token',
    );

    final result = await appAuth.authorizeAndExchangeCode(
      AuthorizationTokenRequest(
        clientId,
        redirectUrl,
        serviceConfiguration: serviceConfig,
        scopes: scopes,
      ),
    );

    return XAuthTokens(
      accessToken: result.accessToken,
      refreshToken: result.refreshToken,
    );
  }
}
