import 'package:dio/dio.dart';
import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/data/data_sources/local/post_local_data_source.dart';
import 'package:vouse_flutter/data/models/local_db/post_model.dart';

import '../../../domain/entities/locaal db/post_entity.dart';
import '../../../domain/repository/local_db/post_local_repository.dart';

class PostLocalRepositoryImpl implements PostLocalRepository {
  final PostLocalDataSource _ds;

  PostLocalRepositoryImpl(this._ds);

  @override
  Future<DataState<void>> savePost(PostEntity post, String userId) async {
    try {
      final postModel = PostModel.fromEntity(post, userId);
      await _ds.insertOrUpdatePost(postModel);
      return const DataSuccess(null);
    } catch (e) {
      return DataFailed(
        DioException(requestOptions: RequestOptions(path: ''), error: e),
      );
    }
  }

  @override
  Future<DataState<List<PostEntity>>> getPostsByUser(String userId) async {
    try {
      final models = await _ds.getPostsByUser(userId);
      final entities = models.map((m) => m.toEntity()).toList();
      return DataSuccess(entities);
    } catch (e) {
      return DataFailed(
        DioException(requestOptions: RequestOptions(path: ''), error: e),
      );
    }
  }

  @override
  Future<DataState<PostEntity?>> getPostById(String postIdLocal) async {
    try {
      final model = await _ds.getPostById(postIdLocal);
      if (model == null) return const DataSuccess(null);
      return DataSuccess(model.toEntity());
    } catch (e) {
      return DataFailed(
        DioException(requestOptions: RequestOptions(path: ''), error: e),
      );
    }
  }

  @override
  Future<DataState<void>> deletePost(String postIdLocal) async {
    try {
      await _ds.deletePost(postIdLocal);
      return const DataSuccess(null);
    } catch (e) {
      return DataFailed(
        DioException(requestOptions: RequestOptions(path: ''), error: e),
      );
    }
  }
}
