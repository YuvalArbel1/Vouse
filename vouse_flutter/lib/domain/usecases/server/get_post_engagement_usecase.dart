// lib/domain/usecases/server/get_post_engagement_usecase.dart

import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/core/usecases/usecase.dart';
import 'package:vouse_flutter/domain/entities/server/post_engagement.dart';
import 'package:vouse_flutter/domain/repository/server/server_repository.dart';

/// Parameters for getting engagement for a specific post by Twitter ID
class GetPostEngagementParams {
  final String postIdX;

  GetPostEngagementParams(this.postIdX);
}

/// A use case that retrieves engagement metrics for a specific post by Twitter ID.
class GetPostEngagementUseCase extends UseCase<DataState<PostEngagement?>, GetPostEngagementParams> {
  final ServerRepository _repository;

  GetPostEngagementUseCase(this._repository);

  @override
  Future<DataState<PostEngagement?>> call({GetPostEngagementParams? params}) {
    if (params == null) {
      throw ArgumentError('GetPostEngagementParams cannot be null');
    }
    return _repository.getEngagement(params.postIdX);
  }
}