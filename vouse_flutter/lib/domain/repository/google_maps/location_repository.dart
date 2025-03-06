// lib/domain/repository/google_maps/location_repository.dart

import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/domain/entities/google_maps/place_location_entity.dart';
import 'package:vouse_flutter/domain/entities/google_maps/place_details_entity.dart';
import 'package:vouse_flutter/domain/entities/google_maps/place_suggestion_entity.dart';

/// Describes location-related operations, combining device location
/// and Google Maps functionality.
abstract class LocationRepository {
  /// Retrieves the user’s current location if permissions/services are enabled.
  ///
  /// Returns [DataSuccess(PlaceLocationEntity)] with lat/long (and optional address),
  /// or [DataFailed] on error (e.g., permission denied).
  Future<DataState<PlaceLocationEntity>> getCurrentLocation();

  /// Reverse geocodes [latitude], [longitude] into a human-readable address string.
  Future<DataState<String>> reverseGeocode(double latitude, double longitude);

  /// Returns a list of place suggestions matching [query] using autocomplete.
  Future<DataState<List<PlaceSuggestionEntity>>> autocompletePlaces(
      String query);

  /// Retrieves place details (coordinates, name, etc.) for a given [placeId].
  Future<DataState<PlaceDetailsEntity>> getPlaceDetails(String placeId);
}
