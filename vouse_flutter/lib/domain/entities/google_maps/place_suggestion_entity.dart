// lib/domain/entities/google_maps/place_suggestion_entity.dart

/// A minimal entity representing a single autocomplete suggestion from Google Maps.
///
/// Contains a [placeId] and a human-readable [description].
class PlaceSuggestionEntity {
  final String placeId;
  final String description;

  /// Creates a [PlaceSuggestionEntity] with a required [placeId] and [description].
  const PlaceSuggestionEntity({
    required this.placeId,
    required this.description,
  });
}
