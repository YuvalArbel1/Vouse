// lib/domain/usecases/google_maps/get_current_location_usecase.dart

import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/domain/entities/google_maps/place_location_entity.dart';
import '../../../core/usecases/usecase.dart';
import '../../repository/google_maps/location_repository.dart';

/// Retrieves the device's current location (including lat/long, optionally an address).
///
/// Returns [DataSuccess(PlaceLocationEntity)] on success,
/// or [DataFailed] on error (e.g., location service disabled, permission denied).
class GetCurrentLocationUseCase
    implements UseCase<DataState<PlaceLocationEntity>, void> {
  final LocationRepository repository;

  /// Requires a [LocationRepository] that can fetch the device location
  /// and optionally perform geocoding.
  GetCurrentLocationUseCase(this.repository);

  @override
  Future<DataState<PlaceLocationEntity>> call({void params}) {
    return repository.getCurrentLocation();
  }
}
