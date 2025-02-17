// lib/domain/entities/place_location_entity.dart

/// A simple entity to represent a chosen location:
/// - latitude/longitude
/// - optional address if reverse geocoded
/// - optional name if you want to store e.g. place name
class PlaceLocationEntity {
  final double latitude;
  final double longitude;
  final String? address;
  final String? name;

  const PlaceLocationEntity({
    required this.latitude,
    required this.longitude,
    this.address,
    this.name,
  });
}
