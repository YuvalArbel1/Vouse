// lib/domain/usecases/server/refresh_post_engagement_usecase.dart

import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/core/usecases/usecase.dart';
import 'package:vouse_flutter/domain/entities/server/post_engagement.dart';
import 'package:vouse_flutter/domain/repository/server/server_repository.dart';

/// Parameters for refreshing engagement for a specific post by Twitter ID
class RefreshPostEngagementParams {
  final String postIdX;

  RefreshPostEngagementParams(this.postIdX);
}

/// A use case that forces a refresh of engagement metrics for a specific post.
class RefreshPostEngagementUseCase
    extends UseCase<DataState<PostEngagement?>, RefreshPostEngagementParams> {
  final ServerRepository _repository;

  RefreshPostEngagementUseCase(this._repository);

  @override
  Future<DataState<PostEngagement?>> call({RefreshPostEngagementParams? params}) {
    if (params == null) {
      throw ArgumentError('RefreshPostEngagementParams cannot be null');
    }
    return _repository.refreshEngagement(params.postIdX);
  }
}