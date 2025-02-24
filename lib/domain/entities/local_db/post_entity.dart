// lib/domain/entities/local_db/post_entity.dart

/// Represents a post within the app's domain.
///
/// Includes various metadata: unique IDs, timestamps, images, location info, etc.
class PostEntity {
  /// A locally generated ID (UUID), used to identify the post in local DB.
  final String postIdLocal;

  /// The published ID from the remote platform (X/Twitter), if available.
  final String? postIdX;

  /// Main text content of the post.
  final String content;

  /// A short title or heading for the post.
  final String title;

  /// Timestamp when the post was created locally.
  final DateTime createdAt;

  /// Timestamp when the post was last updated locally, if any.
  final DateTime? updatedAt;

  /// Timestamp for when the post is scheduled to be published, if any.
  final DateTime? scheduledAt;

  /// Who can see or reply to the post. Typically 'everyone' or similar.
  final String? visibility;

  /// Local file paths for images included with this post.
  final List<String> localImagePaths;

  /// Remote URLs (e.g., Firebase Storage) for images, if already uploaded.
  final List<String> cloudImageUrls;

  /// Optional latitude for location-based posts.
  final double? locationLat;

  /// Optional longitude for location-based posts.
  final double? locationLng;

  /// Optional human-readable address or location text.
  final String? locationAddress;

  /// Constructs a [PostEntity] with required and optional fields.
  PostEntity({
    required this.postIdLocal,
    required this.postIdX,
    required this.content,
    required this.title,
    required this.createdAt,
    this.updatedAt,
    this.scheduledAt,
    this.visibility,
    required this.localImagePaths,
    required this.cloudImageUrls,
    this.locationLat,
    this.locationLng,
    this.locationAddress,
  });

  /// Returns a copy of this entity with any specified fields replaced.
  PostEntity copyWith({
    String? postIdLocal,
    String? postIdX,
    String? content,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? scheduledAt,
    String? visibility,
    List<String>? localImagePaths,
    List<String>? cloudImageUrls,
    double? locationLat,
    double? locationLng,
    String? locationAddress,
  }) {
    return PostEntity(
      postIdLocal: postIdLocal ?? this.postIdLocal,
      postIdX: postIdX ?? this.postIdX,
      content: content ?? this.content,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      visibility: visibility ?? this.visibility,
      localImagePaths: localImagePaths ?? this.localImagePaths,
      cloudImageUrls: cloudImageUrls ?? this.cloudImageUrls,
      locationLat: locationLat ?? this.locationLat,
      locationLng: locationLng ?? this.locationLng,
      locationAddress: locationAddress ?? this.locationAddress,
    );
  }
}
