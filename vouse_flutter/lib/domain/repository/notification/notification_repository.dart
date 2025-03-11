// lib/domain/repository/notification/notification_repository.dart

import 'package:vouse_flutter/core/resources/data_state.dart';

abstract class NotificationRepository {
  /// Register device token with server for push notifications
  Future<DataState<void>> registerDeviceToken(String userId, String token);

  /// Unregister device token with server
  Future<DataState<void>> unregisterDeviceToken(String userId, String token);
}