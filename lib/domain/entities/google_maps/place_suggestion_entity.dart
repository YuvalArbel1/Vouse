// lib/domain/entities/place_suggestion_entity.dart

/// A minimal entity for an autocomplete suggestion.
class PlaceSuggestionEntity {
  final String placeId;
  final String description;

  const PlaceSuggestionEntity({
    required this.placeId,
    required this.description,
  });
}
