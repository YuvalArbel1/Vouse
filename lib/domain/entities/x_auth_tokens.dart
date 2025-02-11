/// A simple domain model representing Twitter (X) tokens.
/// Usually includes at least an accessToken, possibly a refreshToken.
class XAuthTokens {
  final String? accessToken;
  final String? refreshToken;

  const XAuthTokens({
    this.accessToken,
    this.refreshToken,
  });
}
