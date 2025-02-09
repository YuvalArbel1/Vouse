import 'package:flutter_appauth/flutter_appauth.dart';

/// A small wrapper around [FlutterAppAuth] specifically for Twitter OAuth2 PKCE.
/// We'll call this `TwitterOAuth2Client` so your old references remain consistent.
class TwitterOAuth2Client {
  final FlutterAppAuth appAuth;
  final String clientId;
  final String redirectUrl;

  TwitterOAuth2Client({
    required this.appAuth,
    required this.clientId,
    required this.redirectUrl,
  });

  /// Initiates the OAuth2 flow with PKCE, returns the access token or null on failure.
  Future<String?> login({required List<String> scopes}) async {
    // We'll specify Twitter's endpoints
    final serviceConfig = const AuthorizationServiceConfiguration(
      authorizationEndpoint: 'https://twitter.com/i/oauth2/authorize',
      tokenEndpoint: 'https://api.twitter.com/2/oauth2/token',
    );

    // Prepare an auth token request
    final result = await appAuth.authorizeAndExchangeCode(
      AuthorizationTokenRequest(
        clientId,
        redirectUrl,
        serviceConfiguration: serviceConfig,
        scopes: scopes,
        // If your flutter_appauth version doesn't support these, remove them:
        // preferEphemeralSession: true,
        // Additional advanced params if needed
      ),
    );

    // If user cancelled or an error occurred, result might be null
    return result.accessToken; // Return the token if successful
  }
}
