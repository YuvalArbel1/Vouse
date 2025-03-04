// lib/presentation/providers/auth/x/x_connection_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/domain/entities/secure_db/x_auth_tokens.dart';
import 'package:vouse_flutter/presentation/providers/auth/x/x_token_providers.dart';

/// A notifier that manages X (Twitter) connection status.
class XConnectionStatusNotifier extends StateNotifier<bool> {
  final Ref _ref;

  XConnectionStatusNotifier(this._ref) : super(false) {
    // Initialize connection status
    checkConnection();
  }

  /// Checks if X is connected by looking for valid tokens.
  Future<void> checkConnection() async {
    final getTokensUC = _ref.read(getXTokensUseCaseProvider);
    final result = await getTokensUC.call();

    final isConnected =
        result is DataSuccess<XAuthTokens?> && result.data?.accessToken != null;

    state = isConnected;
  }

  /// Manually sets the connection status.
  void setConnected(bool connected) {
    state = connected;
  }
}

/// Provider for X connection status that can be used throughout the app.
final xConnectionStatusProvider =
    StateNotifierProvider<XConnectionStatusNotifier, bool>((ref) {
  return XConnectionStatusNotifier(ref);
});
