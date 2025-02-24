// lib/domain/repository/auth/x_auth_repository.dart

import 'package:vouse_flutter/core/resources/data_state.dart';
import '../../entities/secure_db/x_auth_tokens.dart';

/// Describes OAuth2-based authentication flows for Twitter (X).
abstract class XAuthRepository {
  /// Initiates the sign-in process with X (Twitter),
  /// returning a [DataState] with both access & refresh tokens on success.
  Future<DataState<XAuthTokens>> signInToX();
}
