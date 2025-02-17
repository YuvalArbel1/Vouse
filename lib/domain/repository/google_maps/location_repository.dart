// lib/domain/repositories/location_repository.dart

import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/domain/entities/google_maps/place_location_entity.dart';

import '../../entities/google_maps/place_details_entity.dart';
import '../../entities/google_maps/place_suggestion_entity.dart';

abstract class LocationRepository {
  /// Gets the user’s current location (if permission is granted).
  /// Returns a [DataSuccess] with the lat/long (and possibly an address),
  /// or a [DataFailed] if something went wrong (e.g. permission denied).
  Future<DataState<PlaceLocationEntity>> getCurrentLocation();

  /// Reverse geocodes a lat/long to get an address string.
  /// On success => [DataSuccess] with address; on fail => [DataFailed].
  Future<DataState<String>> reverseGeocode(double latitude, double longitude);


  Future<DataState<List<PlaceSuggestionEntity>>> autocompletePlaces(String query);
  Future<DataState<PlaceDetailsEntity>> getPlaceDetails(String placeId);

}
