// lib/domain/usecases/google_maps/reverse_geocode_usecase.dart

import 'package:dio/dio.dart';
import 'package:vouse_flutter/core/resources/data_state.dart';
import '../../../core/usecases/usecase.dart';
import '../../repository/google_maps/location_repository.dart';

/// Holds [latitude] and [longitude] for a reverse geocoding lookup.
class ReverseGeocodeParams {
  final double latitude;
  final double longitude;

  /// Requires both [latitude] and [longitude].
  ReverseGeocodeParams(this.latitude, this.longitude);
}

/// A use case that converts [latitude] and [longitude] into a human-readable address.
///
/// Calls [LocationRepository.reverseGeocode]. Returns [DataFailed] if params are missing.
class ReverseGeocodeUseCase
    implements UseCase<DataState<String>, ReverseGeocodeParams> {
  final LocationRepository repository;

  /// Requires a [LocationRepository] capable of reverse geocoding.
  ReverseGeocodeUseCase(this.repository);

  @override
  Future<DataState<String>> call({ReverseGeocodeParams? params}) {
    final lat = params?.latitude;
    final lng = params?.longitude;

    if (lat == null || lng == null) {
      return Future.value(
        DataFailed<String>(
          DioException(
            message: 'Missing ReverseGeocodeParams',
            requestOptions: RequestOptions(path: ''),
          ),
        ),
      );
    }

    return repository.reverseGeocode(lat, lng);
  }
}
