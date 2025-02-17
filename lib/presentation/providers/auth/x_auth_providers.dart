import 'package:riverpod/riverpod.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:vouse_flutter/data/clients/twitter/twitter_oauth2_client.dart';
import 'package:vouse_flutter/data/repository/auth/x_auth_repository_impl.dart';
import 'package:vouse_flutter/domain/repository/auth/x_auth_repository.dart';
import 'package:vouse_flutter/domain/usecases/auth/x/sign_in_to_x_usecase.dart';

final flutterAppAuthProvider = Provider<FlutterAppAuth>((ref) {
  // Provide a single instance of FlutterAppAuth
  return const FlutterAppAuth();
});

final twitterOAuth2ClientProvider = Provider<TwitterOAuth2Client>((ref) {
  return TwitterOAuth2Client(
    appAuth: ref.watch(flutterAppAuthProvider),
    clientId: 'MTVHcWdPNUljaUUtdWh4SWs1VFk6MTpjaQ',
    redirectUrl: 'vouseflutter://callback',
  );
});

final xAuthRepositoryProvider = Provider<XAuthRepository>((ref) {
  final client = ref.watch(twitterOAuth2ClientProvider);
  return XAuthRepositoryImpl(client);
});

final signInToXUseCaseProvider = Provider<SignInToXUseCase>((ref) {
  final repo = ref.watch(xAuthRepositoryProvider);
  return SignInToXUseCase(repo);
});
