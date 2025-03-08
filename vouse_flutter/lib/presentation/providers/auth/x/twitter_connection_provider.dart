// lib/presentation/providers/auth/x/twitter_connection_provider.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/domain/entities/secure_db/x_auth_tokens.dart';
import 'package:vouse_flutter/domain/usecases/auth/x/get_x_tokens_usecase.dart';
import 'package:vouse_flutter/domain/usecases/auth/x/save_x_tokens_usecase.dart';
import 'package:vouse_flutter/domain/usecases/auth/x/clear_x_tokens_usecase.dart';
import 'package:vouse_flutter/domain/usecases/server/check_twitter_status_usecase.dart';
import 'package:vouse_flutter/domain/usecases/server/connect_twitter_usecase.dart';
import 'package:vouse_flutter/domain/usecases/server/disconnect_twitter_usecase.dart';
import 'package:vouse_flutter/domain/usecases/server/verify_twitter_tokens_usecase.dart';
import 'package:vouse_flutter/presentation/providers/auth/x/x_token_providers.dart';
import 'package:vouse_flutter/presentation/providers/server/server_providers.dart';

/// Provider state for Twitter connection
enum TwitterConnectionState {
  initial,
  connecting,
  connected,
  disconnecting,
  disconnected,
  error
}

/// State class for Twitter connection
class TwitterConnectionProviderState {
  final TwitterConnectionState connectionState;
  final String? username;
  final String? errorMessage;

  TwitterConnectionProviderState({
    this.connectionState = TwitterConnectionState.initial,
    this.username,
    this.errorMessage,
  });

  TwitterConnectionProviderState copyWith({
    TwitterConnectionState? connectionState,
    String? username,
    String? errorMessage,
  }) {
    return TwitterConnectionProviderState(
      connectionState: connectionState ?? this.connectionState,
      username: username ?? this.username,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Notifier that manages Twitter connection state
class TwitterConnectionNotifier extends StateNotifier<TwitterConnectionProviderState> {
  final GetXTokensUseCase _getXTokensUseCase;
  final SaveXTokensUseCase _saveXTokensUseCase;
  final ClearXTokensUseCase _clearXTokensUseCase;
  final CheckTwitterStatusUseCase _checkTwitterStatusUseCase;
  final ConnectTwitterUseCase _connectTwitterUseCase;
  final DisconnectTwitterUseCase _disconnectTwitterUseCase;
  final VerifyTwitterTokensUseCase _verifyTwitterTokensUseCase;

  TwitterConnectionNotifier({
    required GetXTokensUseCase getXTokensUseCase,
    required SaveXTokensUseCase saveXTokensUseCase,
    required ClearXTokensUseCase clearXTokensUseCase,
    required CheckTwitterStatusUseCase checkTwitterStatusUseCase,
    required ConnectTwitterUseCase connectTwitterUseCase,
    required DisconnectTwitterUseCase disconnectTwitterUseCase,
    required VerifyTwitterTokensUseCase verifyTwitterTokensUseCase,
  })  : _getXTokensUseCase = getXTokensUseCase,
        _saveXTokensUseCase = saveXTokensUseCase,
        _clearXTokensUseCase = clearXTokensUseCase,
        _checkTwitterStatusUseCase = checkTwitterStatusUseCase,
        _connectTwitterUseCase = connectTwitterUseCase,
        _disconnectTwitterUseCase = disconnectTwitterUseCase,
        _verifyTwitterTokensUseCase = verifyTwitterTokensUseCase,
        super(TwitterConnectionProviderState());

  /// Check connection status with server
  Future<void> checkConnectionStatus() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      state = state.copyWith(
        connectionState: TwitterConnectionState.disconnected,
      );
      return;
    }

    try {
      // First check if we have local tokens
      final localTokensResult = await _getXTokensUseCase.call();
      final hasLocalTokens = localTokensResult is DataSuccess<XAuthTokens?> &&
          localTokensResult.data?.accessToken != null;

      // Then check server status
      final serverStatusResult = await _checkTwitterStatusUseCase.call(
        params: CheckTwitterStatusParams(currentUser.uid),
      );

      final isConnectedOnServer = serverStatusResult is DataSuccess<bool> &&
          serverStatusResult.data == true;

      // If connected on server, verify tokens
      if (isConnectedOnServer) {
        final verifyResult = await _verifyTwitterTokensUseCase.call(
          params: VerifyTwitterTokensParams(currentUser.uid),
        );

        // If verification succeeds, we're connected
        if (verifyResult is DataSuccess<String?> && verifyResult.data != null) {
          state = state.copyWith(
            connectionState: TwitterConnectionState.connected,
            username: verifyResult.data,
          );
          return;
        }
      }

      // If we have local tokens but server connection failed, try to re-connect to server
      if (hasLocalTokens && !isConnectedOnServer) {
        await _syncLocalTokensToServer();
        return;
      }

      // Default to disconnected state
      state = state.copyWith(
        connectionState: TwitterConnectionState.disconnected,
      );
    } catch (e) {
      state = state.copyWith(
        connectionState: TwitterConnectionState.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Connect Twitter account
  Future<bool> connectTwitter(XAuthTokens tokens) async {
    try {
      state = state.copyWith(connectionState: TwitterConnectionState.connecting);

      // First save locally
      final saveResult = await _saveXTokensUseCase.call(params: tokens);
      if (saveResult is DataFailed) {
        throw Exception(saveResult.error?.error ?? 'Failed to save tokens locally');
      }

      // Then connect to server
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('No user logged in');
      }

      final serverResult = await _connectTwitterUseCase.call(
        params: ConnectTwitterParams(
          userId: currentUser.uid,
          tokens: tokens,
        ),
      );

      if (serverResult is DataFailed) {
        throw Exception(serverResult.error?.error ?? 'Failed to connect Twitter on server');
      }

      // Verify tokens to get username
      final verifyResult = await _verifyTwitterTokensUseCase.call(
        params: VerifyTwitterTokensParams(currentUser.uid),
      );

      String? username;
      if (verifyResult is DataSuccess<String?>) {
        username = verifyResult.data;
      }

      state = state.copyWith(
        connectionState: TwitterConnectionState.connected,
        username: username,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        connectionState: TwitterConnectionState.error,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Disconnect Twitter account
  Future<bool> disconnectTwitter() async {
    try {
      state = state.copyWith(connectionState: TwitterConnectionState.disconnecting);

      // First clear locally
      final clearResult = await _clearXTokensUseCase.call();
      if (clearResult is DataFailed) {
        throw Exception(clearResult.error?.error ?? 'Failed to clear tokens locally');
      }

      // Then disconnect from server
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('No user logged in');
      }

      final serverResult = await _disconnectTwitterUseCase.call(
        params: DisconnectTwitterParams(currentUser.uid),
      );

      if (serverResult is DataFailed) {
        throw Exception(serverResult.error?.error ?? 'Failed to disconnect Twitter on server');
      }

      state = state.copyWith(
        connectionState: TwitterConnectionState.disconnected,
        username: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        connectionState: TwitterConnectionState.error,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Sync local tokens to server if needed
  Future<void> _syncLocalTokensToServer() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final localTokensResult = await _getXTokensUseCase.call();
      if (localTokensResult is DataSuccess<XAuthTokens?> &&
          localTokensResult.data?.accessToken != null) {

        // Send tokens to server
        await _connectTwitterUseCase.call(
          params: ConnectTwitterParams(
            userId: currentUser.uid,
            tokens: localTokensResult.data!,
          ),
        );

        // Verify tokens
        final verifyResult = await _verifyTwitterTokensUseCase.call(
          params: VerifyTwitterTokensParams(currentUser.uid),
        );

        if (verifyResult is DataSuccess<String?> && verifyResult.data != null) {
          state = state.copyWith(
            connectionState: TwitterConnectionState.connected,
            username: verifyResult.data,
          );
        } else {
          // If verification fails, clear tokens
          await disconnectTwitter();
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error syncing tokens to server: $e');
      }
      // If syncing fails, consider disconnecting
      await disconnectTwitter();
    }
  }
}

/// Provider for Twitter connection
final twitterConnectionProvider =
StateNotifierProvider<TwitterConnectionNotifier, TwitterConnectionProviderState>((ref) {
  return TwitterConnectionNotifier(
    getXTokensUseCase: ref.watch(getXTokensUseCaseProvider),
    saveXTokensUseCase: ref.watch(saveXTokensUseCaseProvider),
    clearXTokensUseCase: ref.watch(clearXTokensUseCaseProvider),
    checkTwitterStatusUseCase: ref.watch(checkTwitterStatusUseCaseProvider),
    connectTwitterUseCase: ref.watch(connectTwitterUseCaseProvider),
    disconnectTwitterUseCase: ref.watch(disconnectTwitterUseCaseProvider),
    verifyTwitterTokensUseCase: ref.watch(verifyTwitterTokensUseCaseProvider),
  );
});