// lib/data/repository/notification/notification_repository_impl.dart

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/data/clients/server/server_api_client.dart';
import 'package:vouse_flutter/domain/repository/notification/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final ServerApiClient _apiClient;

  NotificationRepositoryImpl(this._apiClient);

  @override
  Future<DataState<void>> registerDeviceToken(String userId, String token) async {
    try {
      final response = await _apiClient.registerDeviceToken(userId, {
        'token': token,
        'platform': _getPlatform(),
      });

      if (response.success) {
        return const DataSuccess(null);
      } else {
        return DataFailed(
          DioException(
            requestOptions: RequestOptions(path: ''),
            error: response.message ?? 'Failed to register device token',
          ),
        );
      }
    } on DioException catch (e) {
      return DataFailed(e);
    } catch (e) {
      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: ''),
          error: e.toString(),
        ),
      );
    }
  }

  @override
  Future<DataState<void>> unregisterDeviceToken(String userId, String token) async {
    try {
      final response = await _apiClient.unregisterDeviceToken(userId, token);

      if (response.success) {
        return const DataSuccess(null);
      } else {
        return DataFailed(
          DioException(
            requestOptions: RequestOptions(path: ''),
            error: response.message ?? 'Failed to unregister device token',
          ),
        );
      }
    } on DioException catch (e) {
      return DataFailed(e);
    } catch (e) {
      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: ''),
          error: e.toString(),
        ),
      );
    }
  }

  String _getPlatform() {
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'web';
  }
}