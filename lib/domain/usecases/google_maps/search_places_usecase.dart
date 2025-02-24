// lib/domain/usecases/google_maps/search_places_usecase.dart

import 'package:dio/dio.dart';
import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/core/usecases/usecase.dart';
import 'package:vouse_flutter/domain/entities/google_maps/place_suggestion_entity.dart';
import '../../repository/google_maps/location_repository.dart';

/// Encapsulates the user [query] for place autocomplete lookups.
class SearchPlacesParams {
  final String query;

  /// Requires a non-empty [query].
  SearchPlacesParams(this.query);
}

/// A use case to fetch place suggestions from an autocomplete API
/// via [LocationRepository].
///
/// Returns [DataSuccess<List<PlaceSuggestionEntity>>] on success, or
/// [DataFailed] if [params] is null/empty or if the repository encounters an error.
class SearchPlacesUseCase
    implements UseCase<DataState<List<PlaceSuggestionEntity>>, SearchPlacesParams> {
  final LocationRepository repository;

  SearchPlacesUseCase(this.repository);

  @override
  Future<DataState<List<PlaceSuggestionEntity>>> call({
    SearchPlacesParams? params,
  }) async {
    if (params == null || params.query.isEmpty) {
      return DataFailed(
        DioException(
          message: 'Missing SearchPlacesParams',
          requestOptions: RequestOptions(path: ''),
        ),
      );
    }
    return repository.autocompletePlaces(params.query);
  }
}
