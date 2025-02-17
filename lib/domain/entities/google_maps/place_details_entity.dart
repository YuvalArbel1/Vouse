// lib/domain/entities/place_details_entity.dart

import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Returned after we fetch place details from a placeId (lat/lng, name, etc.).
class PlaceDetailsEntity {
  final LatLng latLng;
  final String? name; // optional if you want place name

  const PlaceDetailsEntity({
    required this.latLng,
    this.name,
  });
}
