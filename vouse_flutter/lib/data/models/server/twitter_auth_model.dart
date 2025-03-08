// lib/data/models/server/twitter_auth_model.dart

import 'package:vouse_flutter/domain/entities/secure_db/x_auth_tokens.dart';

/// Model for sending Twitter OAuth tokens to the server.
class TwitterAuthModel {
  final String accessToken;
  final String refreshToken;
  final String? tokenExpiresAt;

  TwitterAuthModel({
    required this.accessToken,
    required this.refreshToken,
    this.tokenExpiresAt,
  });

  factory TwitterAuthModel.fromJson(Map<String, dynamic> json) {
    return TwitterAuthModel(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      tokenExpiresAt: json['tokenExpiresAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['accessToken'] = accessToken;
    data['refreshToken'] = refreshToken;
    if (tokenExpiresAt != null) {
      data['tokenExpiresAt'] = tokenExpiresAt;
    }
    return data;
  }

  /// Create from domain entity
  factory TwitterAuthModel.fromXAuthTokens(XAuthTokens tokens) {
    return TwitterAuthModel(
      accessToken: tokens.accessToken ?? '',
      refreshToken: tokens.refreshToken ?? '',
      // Add expiration if needed in the future
    );
  }

  /// Convert to domain entity
  XAuthTokens toXAuthTokens() {
    return XAuthTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }
}