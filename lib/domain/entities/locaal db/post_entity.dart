class PostEntity {
  final String postIdLocal;    // local PK, e.g. a UUID
  final String? postIdX;       // null until posted to X
  final String content;        // not empty for draft or scheduled
  final String title;          // required for both
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? scheduledAt;
  final String? visibility;    // "everyone", "verified", "followers", or null
  final List<String> localImagePaths;
  final List<String> cloudImageUrls;
  final double? locationLat;
  final double? locationLng;
  final String? locationAddress;

  const PostEntity({
    required this.postIdLocal,
    this.postIdX,
    required this.content,
    required this.title,
    required this.createdAt,
    this.updatedAt,
    this.scheduledAt,
    this.visibility,
    this.localImagePaths = const [],
    this.cloudImageUrls = const [],
    this.locationLat,
    this.locationLng,
    this.locationAddress,
  });
}
