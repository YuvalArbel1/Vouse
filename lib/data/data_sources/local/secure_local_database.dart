// lib/data/data_sources/local/secure_local_database.dart

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists and retrieves Twitter (X) OAuth tokens in [FlutterSecureStorage].
///
/// Stores both access and refresh tokens using secure key-value pairs.
class XTokenLocalDataSource {
  static const _accessTokenKey = 'twitter_access_token';
  static const _refreshTokenKey = 'twitter_refresh_token';

  final FlutterSecureStorage _secureStorage;

  /// Requires a [FlutterSecureStorage] instance for secure key-value operations.
  XTokenLocalDataSource(this._secureStorage);

  /// Stores the access token. If [token] is null, it removes the token instead.
  Future<void> storeAccessToken(String? token) async {
    if (token == null) {
      await _secureStorage.delete(key: _accessTokenKey);
    } else {
      await _secureStorage.write(key: _accessTokenKey, value: token);
    }
  }

  /// Stores the refresh token. If [token] is null, it removes the token instead.
  Future<void> storeRefreshToken(String? token) async {
    if (token == null) {
      await _secureStorage.delete(key: _refreshTokenKey);
    } else {
      await _secureStorage.write(key: _refreshTokenKey, value: token);
    }
  }

  /// Retrieves the stored access token, or `null` if none is found.
  Future<String?> retrieveAccessToken() {
    return _secureStorage.read(key: _accessTokenKey);
  }

  /// Retrieves the stored refresh token, or `null` if none is found.
  Future<String?> retrieveRefreshToken() {
    return _secureStorage.read(key: _refreshTokenKey);
  }

  /// Clears both access and refresh tokens from secure storage.
  Future<void> clearAll() async {
    await _secureStorage.delete(key: _accessTokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
  }
}
