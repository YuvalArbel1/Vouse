// lib/presentation/providers/auth/x/twitter_connection_provider.dart

import 'package:dio/dio.dart';
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
class TwitterConnectionNotifier
    extends StateNotifier<TwitterConnectionProviderState> {
  final GetXTokensUseCase _getXTokensUseCase;
  final SaveXTokensUseCase _saveXTokensUseCase;
  final ClearXTokensUseCase _clearXTokensUseCase;
  final ConnectTwitterUseCase _connectTwitterUseCase;
  final DisconnectTwitterUseCase _disconnectTwitterUseCase;
  final VerifyTwitterTokensUseCase _verifyTwitterTokensUseCase;
  final Ref _ref;

  // Static flag to maintain state between instances
  static bool _isConnectionChecked = false;
  static bool _isConnected = false;
  static String? _username;
  static bool _checkingInProgress = false;

  TwitterConnectionNotifier({
    required GetXTokensUseCase getXTokensUseCase,
    required SaveXTokensUseCase saveXTokensUseCase,
    required ClearXTokensUseCase clearXTokensUseCase,
    required CheckTwitterStatusUseCase checkTwitterStatusUseCase,
    required ConnectTwitterUseCase connectTwitterUseCase,
    required DisconnectTwitterUseCase disconnectTwitterUseCase,
    required VerifyTwitterTokensUseCase verifyTwitterTokensUseCase,
    required Ref ref,
  })  : _getXTokensUseCase = getXTokensUseCase,
        _saveXTokensUseCase = saveXTokensUseCase,
        _clearXTokensUseCase = clearXTokensUseCase,
        _connectTwitterUseCase = connectTwitterUseCase,
        _disconnectTwitterUseCase = disconnectTwitterUseCase,
        _verifyTwitterTokensUseCase = verifyTwitterTokensUseCase,
        _ref = ref,
        super(TwitterConnectionProviderState(
        connectionState: _isConnectionChecked
            ? (_isConnected
            ? TwitterConnectionState.connected
            : TwitterConnectionState.disconnected)
            : TwitterConnectionState.initial,
        username: _username,
      )) {
    // Only check connection if not already checked
    if (!_isConnectionChecked) {
      checkConnectionStatus(forceCheck: true);
    }
  }

  /// Check connection status
  Future<bool> checkConnectionStatus({bool forceCheck = false}) async {
    // Skip redundant checks
    if (_checkingInProgress && !forceCheck) {
      return _isConnected;
    }

    if (_isConnectionChecked && !forceCheck) {
      return _isConnected;
    }

    _checkingInProgress = true;

    try {
      // First, rely purely on local token existence
      final localTokensResult = await _getXTokensUseCase.call();
      final hasLocalTokens = localTokensResult is DataSuccess<XAuthTokens?> &&
          localTokensResult.data?.accessToken != null;

      // If we have local tokens, consider connected - simple rule
      if (hasLocalTokens) {
        // Just get username in background - don't make connection status depend on it
        _getUsername().then((username) {
          if (username != null && mounted) {
            state = TwitterConnectionProviderState(
              connectionState: TwitterConnectionState.connected,
              username: username,
            );
            _username = username;
          }
        });

        _isConnected = true;
        _isConnectionChecked = true;
        state = TwitterConnectionProviderState(
          connectionState: TwitterConnectionState.connected,
          username: _username,
        );
        return true;
      } else {
        _isConnected = false;
        _isConnectionChecked = true;
        state = TwitterConnectionProviderState(
          connectionState: TwitterConnectionState.disconnected,
        );
        return false;
      }
    } finally {
      _checkingInProgress = false;
    }
  }

  /// Get username in background, don't block UI
  Future<String?> _getUsername() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return null;

      final verifyResult = await _verifyTwitterTokensUseCase.call(
        params: VerifyTwitterTokensParams(currentUser.uid),
      );

      if (verifyResult is DataSuccess<String?> && verifyResult.data != null) {
        return verifyResult.data;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Connect Twitter account
  Future<bool> connectTwitter(XAuthTokens tokens) async {
    try {
      state = state.copyWith(connectionState: TwitterConnectionState.connecting);

      // First just save locally - most important step
      final saveResult = await _saveXTokensUseCase.call(params: tokens);
      if (saveResult is DataFailed) {
        throw Exception(saveResult.error?.error ?? 'Failed to save tokens locally');
      }

      // Now we can consider the user connected
      _isConnected = true;
      _isConnectionChecked = true;
      state = TwitterConnectionProviderState(
        connectionState: TwitterConnectionState.connected,
      );

      // Try to get username and connect to server in background
      _connectToServerInBackground(tokens);

      return true;
    } catch (e) {
      debugPrint('Error connecting to Twitter: $e');
      _isConnected = false;
      state = TwitterConnectionProviderState(
        connectionState: TwitterConnectionState.error,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Background connection to server - don't block UI flow
  Future<void> _connectToServerInBackground(XAuthTokens tokens) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // Send tokens to server
      await _connectTwitterUseCase.call(
        params: ConnectTwitterParams(
          userId: currentUser.uid,
          tokens: tokens,
        ),
      );

      // Get username
      final verifyResult = await _verifyTwitterTokensUseCase.call(
        params: VerifyTwitterTokensParams(currentUser.uid),
      );

      if (verifyResult is DataSuccess<String?> && verifyResult.data != null && mounted) {
        _username = verifyResult.data;
        state = TwitterConnectionProviderState(
          connectionState: TwitterConnectionState.connected,
          username: _username,
        );
      }
    } catch (e) {
      debugPrint('Background server connection error: $e');
      // Don't change connected state - local tokens are what matter
    }
  }

  /// Disconnect Twitter account - simple approach
  Future<bool> disconnectTwitter() async {
    try {
      // Set disconnecting state
      state = state.copyWith(connectionState: TwitterConnectionState.disconnecting);

      // Clear local tokens - this is the most important part
      final clearResult = await _clearXTokensUseCase.call();
      if (clearResult is DataFailed) {
        throw Exception(clearResult.error?.error ?? 'Failed to clear tokens locally');
      }

      // Set as disconnected immediately
      _isConnected = false;
      _username = null;
      state = TwitterConnectionProviderState(
        connectionState: TwitterConnectionState.disconnected,
      );

      // Background task to disconnect from server
      _disconnectFromServerInBackground();

      return true;
    } catch (e) {
      debugPrint('Error disconnecting from Twitter: $e');

      // Even on error, ensure UI is updated to disconnected
      _isConnected = false;
      _username = null;
      state = TwitterConnectionProviderState(
        connectionState: TwitterConnectionState.disconnected,
      );

      return true; // Return success so UI updates properly
    }
  }

  /// Background disconnection from server - don't block UI
  Future<void> _disconnectFromServerInBackground() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      await _disconnectTwitterUseCase.call(
        params: DisconnectTwitterParams(currentUser.uid),
      );
    } catch (e) {
      debugPrint('Background server disconnection error: $e');
      // Don't change state - local token removal is what matters
    }
  }
}

/// Provider for Twitter connection
final twitterConnectionProvider = StateNotifierProvider<TwitterConnectionNotifier, TwitterConnectionProviderState>((ref) {
  return TwitterConnectionNotifier(
    getXTokensUseCase: ref.watch(getXTokensUseCaseProvider),
    saveXTokensUseCase: ref.watch(saveXTokensUseCaseProvider),
    clearXTokensUseCase: ref.watch(clearXTokensUseCaseProvider),
    checkTwitterStatusUseCase: ref.watch(checkTwitterStatusUseCaseProvider),
    connectTwitterUseCase: ref.watch(connectTwitterUseCaseProvider),
    disconnectTwitterUseCase: ref.watch(disconnectTwitterUseCaseProvider),
    verifyTwitterTokensUseCase: ref.watch(verifyTwitterTokensUseCaseProvider),
    ref: ref,
  );
});