import 'package:flutter_appauth/flutter_appauth.dart';
// Import the domain XAuthTokens
import 'package:vouse_flutter/domain/entities/secure_db/x_auth_tokens.dart';

class TwitterOAuth2Client {
  final FlutterAppAuth appAuth;
  final String clientId;
  final String redirectUrl;

  TwitterOAuth2Client({
    required this.appAuth,
    required this.clientId,
    required this.redirectUrl,
  });

  /// Initiates OAuth2 with PKCE, returning both access & refresh tokens if available
  /// (You must have 'offline.access' in [scopes] to get a refresh token.)
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

    // Return domain's XAuthTokens
    return XAuthTokens(
      accessToken: result.accessToken,
      refreshToken: result.refreshToken,
    );
  }
}
