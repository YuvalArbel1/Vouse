import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// A data source for storing/retrieving Twitter tokens in flutter_secure_storage.
class XTokenLocalDataSource {
  static const _accessTokenKey = 'twitter_access_token';
  static const _refreshTokenKey = 'twitter_refresh_token';

  final FlutterSecureStorage _secureStorage;

  XTokenLocalDataSource(this._secureStorage);

  /// Store access token (null => remove)
  Future<void> storeAccessToken(String? token) async {
    if (token == null) {
      await _secureStorage.delete(key: _accessTokenKey);
    } else {
      await _secureStorage.write(key: _accessTokenKey, value: token);
    }
  }

  /// Store refresh token (null => remove)
  Future<void> storeRefreshToken(String? token) async {
    if (token == null) {
      await _secureStorage.delete(key: _refreshTokenKey);
    } else {
      await _secureStorage.write(key: _refreshTokenKey, value: token);
    }
  }

  /// Retrieve access token
  Future<String?> retrieveAccessToken() {
    return _secureStorage.read(key: _accessTokenKey);
  }

  /// Retrieve refresh token
  Future<String?> retrieveRefreshToken() {
    return _secureStorage.read(key: _refreshTokenKey);
  }

  /// Clear both
  Future<void> clearAll() async {
    await _secureStorage.delete(key: _accessTokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
  }
}
