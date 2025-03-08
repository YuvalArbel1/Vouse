// lib/domain/usecases/server/get_post_engagements_usecase.dart

import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/core/usecases/usecase.dart';
import 'package:vouse_flutter/domain/entities/server/post_engagement.dart';
import 'package:vouse_flutter/domain/repository/server/server_repository.dart';

/// A use case that retrieves all engagement metrics from the server.
class GetPostEngagementsUseCase extends UseCase<DataState<List<PostEngagement>>, void> {
  final ServerRepository _repository;

  GetPostEngagementsUseCase(this._repository);

  @override
  Future<DataState<List<PostEngagement>>> call({void params}) {
    return _repository.getAllEngagements();
  }
}