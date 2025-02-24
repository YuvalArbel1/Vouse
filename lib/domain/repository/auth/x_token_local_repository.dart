// lib/domain/repository/auth/x_token_local_repository.dart

import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/domain/entities/secure_db/x_auth_tokens.dart';

/// A contract for securely storing and retrieving X (Twitter) OAuth tokens.
abstract class XTokenLocalRepository {
  /// Saves [tokens] to secure storage, returning [DataSuccess] on success or [DataFailed] otherwise.
  Future<DataState<void>> saveTokens(XAuthTokens tokens);

  /// Retrieves stored tokens, or returns `null` if not found.
  Future<DataState<XAuthTokens?>> getTokens();

  /// Clears both access and refresh tokens from secure storage.
  Future<DataState<void>> clearTokens();
}
