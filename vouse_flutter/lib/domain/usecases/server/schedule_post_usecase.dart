// lib/domain/usecases/server/schedule_post_usecase.dart

import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/core/usecases/usecase.dart';
import 'package:vouse_flutter/domain/entities/local_db/post_entity.dart';
import 'package:vouse_flutter/domain/repository/server/server_repository.dart';

/// Parameters for scheduling a post on the server
class SchedulePostParams {
  final PostEntity post;

  SchedulePostParams(this.post);
}

/// A use case that schedules a post on the server.
///
/// Returns the server ID of the newly created post.
class SchedulePostUseCase extends UseCase<DataState<String>, SchedulePostParams> {
  final ServerRepository _repository;

  SchedulePostUseCase(this._repository);

  @override
  Future<DataState<String>> call({SchedulePostParams? params}) {
    if (params == null) {
      throw ArgumentError('SchedulePostParams cannot be null');
    }
    return _repository.schedulePost(params.post);
  }
}