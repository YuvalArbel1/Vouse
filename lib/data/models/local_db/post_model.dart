import 'dart:convert';

import '../../../domain/entities/locaal db/post_entity.dart';

class PostModel extends PostEntity {
  final String userId; // this is the foreign key referencing user.userId

  PostModel({
    required this.userId,
    required super.postIdLocal,
    super.postIdX,
    required super.content,
    required super.title,
    required super.createdAt,
    super.updatedAt,
    super.scheduledAt,
    super.visibility,
    super.localImagePaths = const [],
    super.cloudImageUrls = const [],
    super.locationLat,
    super.locationLng,
    super.locationAddress,
  });

  factory PostModel.fromMap(Map<String, dynamic> map) {
    return PostModel(
      userId: map['userId'],
      postIdLocal: map['postIdLocal'],
      postIdX: map['postIdX'],
      content: map['content'],
      title: map['title'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
      scheduledAt: map['scheduledAt'] != null ? DateTime.parse(map['scheduledAt']) : null,
      visibility: map['visibility'],
      localImagePaths: map['localImagePaths'] == null
          ? []
          : List<String>.from(jsonDecode(map['localImagePaths'])),
      cloudImageUrls: map['cloudImageUrls'] == null
          ? []
          : List<String>.from(jsonDecode(map['cloudImageUrls'])),
      locationLat: map['locationLat'],
      locationLng: map['locationLng'],
      locationAddress: map['locationAddress'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'postIdLocal': postIdLocal,
      'postIdX': postIdX,
      'content': content,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'scheduledAt': scheduledAt?.toIso8601String(),
      'visibility': visibility,
      'localImagePaths': jsonEncode(localImagePaths),
      'cloudImageUrls': jsonEncode(cloudImageUrls),
      'locationLat': locationLat,
      'locationLng': locationLng,
      'locationAddress': locationAddress,
    };
  }

  // Utility: fromEntity => PostModel
  static PostModel fromEntity(PostEntity entity, String userId) {
    return PostModel(
      userId: userId,
      postIdLocal: entity.postIdLocal,
      postIdX: entity.postIdX,
      content: entity.content,
      title: entity.title,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      scheduledAt: entity.scheduledAt,
      visibility: entity.visibility,
      localImagePaths: entity.localImagePaths,
      cloudImageUrls: entity.cloudImageUrls,
      locationLat: entity.locationLat,
      locationLng: entity.locationLng,
      locationAddress: entity.locationAddress,
    );
  }

  // Utility: toEntity => PostEntity
  PostEntity toEntity() {
    return PostEntity(
      postIdLocal: postIdLocal,
      postIdX: postIdX,
      content: content,
      title: title,
      createdAt: createdAt,
      updatedAt: updatedAt,
      scheduledAt: scheduledAt,
      visibility: visibility,
      localImagePaths: localImagePaths,
      cloudImageUrls: cloudImageUrls,
      locationLat: locationLat,
      locationLng: locationLng,
      locationAddress: locationAddress,
    );
  }
}
