// lib/domain/entities/google_maps/place_details_entity.dart

import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Represents place details fetched by an API lookup of a placeId.
///
/// Contains a [latLng] coordinate and an optional [name] (e.g., POI name).
class PlaceDetailsEntity {
  final LatLng latLng;
  final String? name;

  /// Creates a [PlaceDetailsEntity] with a required [latLng] and optional [name].
  const PlaceDetailsEntity({
    required this.latLng,
    this.name,
  });
}
