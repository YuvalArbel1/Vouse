// lib/domain/entities/secure_db/x_auth_tokens.dart

/// Represents Twitter (X) OAuth tokens within the domain.
///
/// Typically includes an [accessToken] and optional [refreshToken].
class XAuthTokens {
  final String? accessToken;
  final String? refreshToken;

  /// Creates [XAuthTokens] with optional [accessToken] and [refreshToken].
  const XAuthTokens({
    this.accessToken,
    this.refreshToken,
  });
}
