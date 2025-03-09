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
  final DateTime lastChecked; // Add timestamp to track when status was last checked

  TwitterConnectionProviderState({
    this.connectionState = TwitterConnectionState.initial,
    this.username,
    this.errorMessage,
    DateTime? lastChecked,
  }) : lastChecked = lastChecked ?? DateTime.now();

  TwitterConnectionProviderState copyWith({
    TwitterConnectionState? connectionState,
    String? username,
    String? errorMessage,
    DateTime? lastChecked,
  }) {
    return TwitterConnectionProviderState(
      connectionState: connectionState ?? this.connectionState,
      username: username ?? this.username,
      errorMessage: errorMessage ?? this.errorMessage,
      lastChecked: lastChecked ?? DateTime.now(), // Always update timestamp when state changes
    );
  }
}

/// Notifier that manages Twitter connection state
class TwitterConnectionNotifier
    extends StateNotifier<TwitterConnectionProviderState> {
  final GetXTokensUseCase _getXTokensUseCase;
  final SaveXTokensUseCase _saveXTokensUseCase;
  final ClearXTokensUseCase _clearXTokensUseCase;
  final CheckTwitterStatusUseCase _checkTwitterStatusUseCase;
  final ConnectTwitterUseCase _connectTwitterUseCase;
  final DisconnectTwitterUseCase _disconnectTwitterUseCase;
  final VerifyTwitterTokensUseCase _verifyTwitterTokensUseCase;
  final Ref _ref;

  // Keep track of whether a check is in progress to prevent multiple simultaneous calls
  bool _isCheckingStatus = false;

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
        _checkTwitterStatusUseCase = checkTwitterStatusUseCase,
        _connectTwitterUseCase = connectTwitterUseCase,
        _disconnectTwitterUseCase = disconnectTwitterUseCase,
        _verifyTwitterTokensUseCase = verifyTwitterTokensUseCase,
        _ref = ref,
        super(TwitterConnectionProviderState()) {
    // Automatically check status on initialization
    checkConnectionStatus();
  }

  /// Check connection status with server
  Future<bool> checkConnectionStatus({bool forceCheck = false}) async {
    // Prevent multiple simultaneous checks
    if (_isCheckingStatus && !forceCheck) {
      return state.connectionState == TwitterConnectionState.connected;
    }

    _isCheckingStatus = true;

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        state = state.copyWith(
          connectionState: TwitterConnectionState.disconnected,
        );
        return false;
      }

      // Skip rechecking if we've checked recently (within 30 seconds) and not forcing
      final now = DateTime.now();
      final timeSinceLastCheck = now.difference(state.lastChecked);
      if (!forceCheck && timeSinceLastCheck.inSeconds < 30 &&
          state.connectionState != TwitterConnectionState.initial) {
        _isCheckingStatus = false;
        return state.connectionState == TwitterConnectionState.connected;
      }

      debugPrint("Checking Twitter connection status for user: ${currentUser.uid}");

      // First check if we have local tokens
      final localTokensResult = await _getXTokensUseCase.call();
      final hasLocalTokens = localTokensResult is DataSuccess<XAuthTokens?> &&
          localTokensResult.data?.accessToken != null;

      debugPrint("Has local tokens: $hasLocalTokens");

      // Then check server status
      final serverStatusResult = await _checkTwitterStatusUseCase.call(
        params: CheckTwitterStatusParams(currentUser.uid),
      );

      final isConnectedOnServer = serverStatusResult is DataSuccess<bool> &&
          serverStatusResult.data == true;

      debugPrint("Is connected on server: $isConnectedOnServer");

      // If connected on server, verify tokens
      if (isConnectedOnServer) {
        final verifyResult = await _verifyTwitterTokensUseCase.call(
          params: VerifyTwitterTokensParams(currentUser.uid),
        );

        // If verification succeeds, we're connected
        if (verifyResult is DataSuccess<String?> && verifyResult.data != null) {
          debugPrint("Twitter verification succeeded for username: ${verifyResult.data}");
          state = state.copyWith(
            connectionState: TwitterConnectionState.connected,
            username: verifyResult.data,
          );
          return true;
        } else {
          debugPrint("Twitter verification failed");
        }
      }

      // If we have local tokens but server connection failed, try to re-connect to server
      if (hasLocalTokens && !isConnectedOnServer) {
        debugPrint("Has local tokens but not connected on server, attempting to sync");
        final synced = await _syncLocalTokensToServer();
        if (synced) {
          return true;
        }
      }

      // Default to disconnected state
      debugPrint("Setting Twitter connection state to disconnected");
      state = state.copyWith(
        connectionState: TwitterConnectionState.disconnected,
      );
      return false;
    } catch (e) {
      debugPrint("Error checking Twitter connection: $e");
      state = state.copyWith(
        connectionState: TwitterConnectionState.error,
        errorMessage: e.toString(),
      );
      return false;
    } finally {
      _isCheckingStatus = false;
    }
  }

  /// Connect Twitter account
  Future<bool> connectTwitter(XAuthTokens tokens) async {
    try {
      debugPrint("Starting Twitter connection process");
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

      // Debug log to see tokens and connection details
      final serverUrl = _ref.read(serverUrlProvider);
      debugPrint('Attempting to connect to server at $serverUrl');
      debugPrint('User ID: ${currentUser.uid}');
      debugPrint('Access token (first 10 chars): ${tokens.accessToken?.substring(0, 10)}...');

      final serverResult = await _connectTwitterUseCase.call(
        params: ConnectTwitterParams(
          userId: currentUser.uid,
          tokens: tokens,
        ),
      );

      if (serverResult is DataFailed) {
        final errorDetails = serverResult.error?.toString() ?? 'No error details';
        debugPrint('Server connection failed: $errorDetails');

        // Log the complete error for diagnosis
        if (serverResult.error is DioException) {
          final dioError = serverResult.error as DioException;
          debugPrint('Dio error type: ${dioError.type}');
          debugPrint('Dio error message: ${dioError.message}');
          debugPrint('Dio error response: ${dioError.response?.data}');
        }

        throw Exception(serverResult.error?.error ?? 'Failed to connect Twitter on server');
      }

      // Verify tokens to get username
      final verifyResult = await _verifyTwitterTokensUseCase.call(
        params: VerifyTwitterTokensParams(currentUser.uid),
      );

      String? username;
      if (verifyResult is DataSuccess<String?>) {
        username = verifyResult.data;
        debugPrint('Verified tokens for username: $username');
      } else if (verifyResult is DataFailed) {
        debugPrint('Token verification failed: ${verifyResult.error?.error}');
      }

      state = state.copyWith(
        connectionState: TwitterConnectionState.connected,
        username: username,
      );

      return true;
    } catch (e) {
      debugPrint('Twitter connection error: $e');
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
      debugPrint("Starting Twitter disconnection process");
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
      debugPrint("Error disconnecting Twitter: $e");
      state = state.copyWith(
        connectionState: TwitterConnectionState.error,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Sync local tokens to server if needed
  Future<bool> _syncLocalTokensToServer() async {
    try {
      debugPrint("Attempting to sync local tokens to server");
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return false;

      final localTokensResult = await _getXTokensUseCase.call();
      if (localTokensResult is DataSuccess<XAuthTokens?> &&
          localTokensResult.data?.accessToken != null) {
        debugPrint("Found local tokens, sending to server");
        // Send tokens to server
        final connectResult = await _connectTwitterUseCase.call(
          params: ConnectTwitterParams(
            userId: currentUser.uid,
            tokens: localTokensResult.data!,
          ),
        );

        if (connectResult is DataFailed) {
          debugPrint("Failed to send local tokens to server: ${connectResult.error?.error}");
          return false;
        }

        // Verify tokens
        final verifyResult = await _verifyTwitterTokensUseCase.call(
          params: VerifyTwitterTokensParams(currentUser.uid),
        );

        if (verifyResult is DataSuccess<String?> && verifyResult.data != null) {
          debugPrint("Token verification successful after sync for username: ${verifyResult.data}");
          state = state.copyWith(
            connectionState: TwitterConnectionState.connected,
            username: verifyResult.data,
          );
          return true;
        } else {
          debugPrint("Token verification failed after sync");
          // If verification fails, clear tokens
          await disconnectTwitter();
          return false;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Error syncing tokens to server: $e');
      // If syncing fails, consider disconnecting
      await disconnectTwitter();
      return false;
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