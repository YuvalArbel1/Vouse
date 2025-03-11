// lib/domain/usecases/notification/unregister_device_token_usecase.dart

import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/core/usecases/usecase.dart';
import 'package:vouse_flutter/domain/repository/notification/notification_repository.dart';

class UnregisterDeviceTokenParams {
  final String userId;
  final String token;

  UnregisterDeviceTokenParams({
    required this.userId,
    required this.token,
  });
}

class UnregisterDeviceTokenUseCase extends UseCase<DataState<void>, UnregisterDeviceTokenParams> {
  final NotificationRepository _repository;

  UnregisterDeviceTokenUseCase(this._repository);

  @override
  Future<DataState<void>> call({UnregisterDeviceTokenParams? params}) {
    if (params == null) {
      throw ArgumentError('UnregisterDeviceTokenParams cannot be null');
    }
    return _repository.unregisterDeviceToken(params.userId, params.token);
  }
}