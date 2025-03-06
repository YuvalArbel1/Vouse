// lib/presentation/providers/auth/x/x_auth_providers.dart

import 'package:riverpod/riverpod.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:vouse_flutter/core/config/app_secrets.dart';
import 'package:vouse_flutter/data/clients/twitter/twitter_oauth2_client.dart';
import 'package:vouse_flutter/data/repository/auth/x_auth_repository_impl.dart';
import 'package:vouse_flutter/domain/repository/auth/x_auth_repository.dart';
import 'package:vouse_flutter/domain/usecases/auth/x/sign_in_to_x_usecase.dart';

/// Provides a single instance of [FlutterAppAuth].
final flutterAppAuthProvider = Provider<FlutterAppAuth>((ref) {
  return const FlutterAppAuth();
});

/// Creates a [TwitterOAuth2Client] using our secrets from [AppSecrets].
final twitterOAuth2ClientProvider = Provider<TwitterOAuth2Client>((ref) {
  return TwitterOAuth2Client(
    appAuth: ref.watch(flutterAppAuthProvider),
    clientId: AppSecrets.xClientId,
    redirectUrl: AppSecrets.xRedirectUrl,
  );
});

/// Provides the [XAuthRepository] that uses [twitterOAuth2ClientProvider].
final xAuthRepositoryProvider = Provider<XAuthRepository>((ref) {
  final client = ref.watch(twitterOAuth2ClientProvider);
  return XAuthRepositoryImpl(client);
});

/// Provides a [SignInToXUseCase] for the X (Twitter) OAuth flow.
final signInToXUseCaseProvider = Provider<SignInToXUseCase>((ref) {
  final repo = ref.watch(xAuthRepositoryProvider);
  return SignInToXUseCase(repo);
});
