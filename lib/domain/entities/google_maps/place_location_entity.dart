// lib/domain/entities/google_maps/place_location_entity.dart

/// Represents a chosen location in the app.
///
/// Includes [latitude], [longitude], and optional [address] or [name].
class PlaceLocationEntity {
  final double latitude;
  final double longitude;
  final String? address;
  final String? name;

  /// Creates a [PlaceLocationEntity] with [latitude], [longitude], and
  /// optional [address] or [name].
  const PlaceLocationEntity({
    required this.latitude,
    required this.longitude,
    this.address,
    this.name,
  });
}
