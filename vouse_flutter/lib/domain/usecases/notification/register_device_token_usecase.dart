// lib/domain/usecases/notification/register_device_token_usecase.dart

import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/core/usecases/usecase.dart';
import 'package:vouse_flutter/domain/repository/notification/notification_repository.dart';

class RegisterDeviceTokenParams {
  final String userId;
  final String token;

  RegisterDeviceTokenParams({
    required this.userId,
    required this.token,
  });
}

class RegisterDeviceTokenUseCase extends UseCase<DataState<void>, RegisterDeviceTokenParams> {
  final NotificationRepository _repository;

  RegisterDeviceTokenUseCase(this._repository);

  @override
  Future<DataState<void>> call({RegisterDeviceTokenParams? params}) {
    if (params == null) {
      throw ArgumentError('RegisterDeviceTokenParams cannot be null');
    }
    return _repository.registerDeviceToken(params.userId, params.token);
  }
}