// lib/presentation/providers/notification/notification_provider.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/domain/usecases/notification/register_device_token_usecase.dart';
import 'package:vouse_flutter/domain/usecases/notification/unregister_device_token_usecase.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Create providers for notification use cases
import '../server/server_providers.dart';

/// Provider for RegisterDeviceTokenUseCase
final registerDeviceTokenUseCaseProvider = Provider<RegisterDeviceTokenUseCase>((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  return RegisterDeviceTokenUseCase(repository);
});

/// Provider for UnregisterDeviceTokenUseCase
final unregisterDeviceTokenUseCaseProvider = Provider<UnregisterDeviceTokenUseCase>((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  return UnregisterDeviceTokenUseCase(repository);
});

/// A notifier that manages notification status
class NotificationStatusNotifier extends StateNotifier<bool> {
  final RegisterDeviceTokenUseCase _registerDeviceTokenUseCase;
  final UnregisterDeviceTokenUseCase _unregisterDeviceTokenUseCase;

  // Local storage key for notification status
  static const String _notificationStatusKey = 'notification_status_enabled';
  static const String _fcmTokenKey = 'fcm_token';

  NotificationStatusNotifier({
    required RegisterDeviceTokenUseCase registerDeviceTokenUseCase,
    required UnregisterDeviceTokenUseCase unregisterDeviceTokenUseCase,
  }) : _registerDeviceTokenUseCase = registerDeviceTokenUseCase,
        _unregisterDeviceTokenUseCase = unregisterDeviceTokenUseCase,
        super(false); // Default to disabled

  /// Check the current notification status
  Future<void> checkStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isEnabled = prefs.getBool(_notificationStatusKey) ?? false;
      state = isEnabled;
    } catch (e) {
      debugPrint('Error checking notification status: $e');
      state = false;
    }
  }

  /// Enable notifications for a user
  Future<bool> enableNotifications(String userId, String token) async {
    try {
      // Call the use case to register the token
      final result = await _registerDeviceTokenUseCase.call(
        params: RegisterDeviceTokenParams(
          userId: userId,
          token: token,
        ),
      );

      if (result is DataSuccess) {
        // Save the status and token locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_notificationStatusKey, true);
        await prefs.setString(_fcmTokenKey, token);

        // Update state
        state = true;
        return true;
      } else {
        debugPrint('Error enabling notifications: ${result.error?.error}');
        return false;
      }
    } catch (e) {
      debugPrint('Error enabling notifications: $e');
      return false;
    }
  }

  /// Disable notifications for a user
  Future<bool> disableNotifications(String userId) async {
    try {
      // Get the saved token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_fcmTokenKey);

      if (token == null) {
        debugPrint('No token found to unregister');
        await prefs.setBool(_notificationStatusKey, false);
        state = false;
        return true;
      }

      // Call the use case to unregister the token
      final result = await _unregisterDeviceTokenUseCase.call(
        params: UnregisterDeviceTokenParams(
          userId: userId,
          token: token,
        ),
      );

      if (result is DataSuccess) {
        // Update local storage
        await prefs.setBool(_notificationStatusKey, false);
        await prefs.remove(_fcmTokenKey);

        // Update state
        state = false;
        return true;
      } else {
        debugPrint('Error disabling notifications: ${result.error?.error}');
        return false;
      }
    } catch (e) {
      debugPrint('Error disabling notifications: $e');
      return false;
    }
  }
}

/// Provider for notification status
final notificationStatusProvider = StateNotifierProvider<NotificationStatusNotifier, bool>((ref) {
  return NotificationStatusNotifier(
    registerDeviceTokenUseCase: ref.watch(registerDeviceTokenUseCaseProvider),
    unregisterDeviceTokenUseCase: ref.watch(unregisterDeviceTokenUseCaseProvider),
  );
});