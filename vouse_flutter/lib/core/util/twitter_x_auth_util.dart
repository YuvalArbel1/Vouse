// lib/core/util/twitter_x_auth_util.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../domain/entities/secure_db/x_auth_tokens.dart';

import '../../presentation/providers/auth/x/x_auth_providers.dart';
import '../../presentation/providers/auth/x/twitter_connection_provider.dart';
import '../../core/resources/data_state.dart';

/// A utility class for handling Twitter/X authentication operations.
///
/// Centralizes authentication logic to avoid code duplication across the app.
class TwitterXAuthUtil {
  /// Initiates Twitter OAuth sign-in flow, retrieves tokens, then stores them securely.
  ///
  /// Uses the improved TwitterConnectionProvider to handle storage and server connection.
  /// Shows appropriate loading/success/error toasts and handles mounted state checking.
  /// Returns true if connection was successful, false otherwise.
  static Future<bool> connectToX(
      WidgetRef ref, {
        required Function(bool) setLoadingState,
        required bool mounted,
      }) async {
    // Set loading state to true
    setLoadingState(true);

    try {
      // Start the sign-in flow
      final result = await ref.read(signInToXUseCaseProvider).call();

      if (!mounted) return false;

      if (result is DataSuccess<XAuthTokens> && result.data != null) {
        final tokens = result.data!;

        // Use the TwitterConnectionProvider for consistent handling
        final connectResult = await ref.read(twitterConnectionProvider.notifier).connectTwitter(tokens);

        if (!mounted) return false;

        if (connectResult) {
          // Show success toast
          toast("X account connected successfully");
          return true;
        } else {
          toast("Failed to connect Twitter account");
          return false;
        }
      } else if (result is DataFailed<XAuthTokens>) {
        final errorMsg = result.error?.error ?? 'Unknown error';
        toast("Twitter Auth Error: $errorMsg");
        return false;
      }

      return false;
    } finally {
      // Only reset loading state if the widget is still mounted
      if (mounted) {
        setLoadingState(false);
      }
    }
  }

  /// Disconnects the X account using the improved TwitterConnectionProvider.
  ///
  /// Shows a confirmation dialog before proceeding.
  /// Returns true if disconnect was successful, false otherwise.
  static Future<bool> disconnectFromX(
      BuildContext context,
      WidgetRef ref, {
        required Function(bool) setLoadingState,
        required bool mounted,
      }) async {
    // Show confirmation dialog
    final shouldDisconnect = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disconnect X Account'),
        content: const Text(
            'Are you sure you want to disconnect your X account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Disconnect',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ??
        false;

    if (!shouldDisconnect) return false;

    // Set loading state
    setLoadingState(true);

    try {
      // Use the TwitterConnectionProvider for consistent handling
      final disconnectResult = await ref.read(twitterConnectionProvider.notifier).disconnectTwitter();

      if (!mounted) return false;

      if (disconnectResult) {
        // Show success toast
        toast('X account disconnected successfully');
        return true;
      } else {
        toast('Failed to disconnect Twitter account');
        return false;
      }
    } catch (e) {
      toast('Error disconnecting X: $e');
      return false;
    } finally {
      if (mounted) {
        setLoadingState(false);
      }
    }
  }
}