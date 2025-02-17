import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/core/usecases/usecase.dart';
import 'package:vouse_flutter/domain/entities/locaal%20db/user_entity.dart';

import '../../repository/home/user_local_repository.dart';

class GetUserParams {
  final String userId;
  GetUserParams(this.userId);
}

class GetUserUseCase extends UseCase<DataState<UserEntity?>, GetUserParams> {
  final UserLocalRepository _repository;

  GetUserUseCase(this._repository);

  @override
  Future<DataState<UserEntity?>> call({GetUserParams? params}) {
    return _repository.getUser(params!.userId);
  }
}
