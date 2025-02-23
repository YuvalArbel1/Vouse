// lib/data/models/local_db/post_model.dart

import 'dart:convert';

import '../../../domain/entities/locaal db/post_entity.dart';

/// A model that extends [PostEntity] and provides SQLite-friendly serialization.
///
/// Includes a [userId] field referencing the user's ID in the 'user' table.
class PostModel extends PostEntity {
  /// References [user.userId].
  final String userId;

  /// Constructs a [PostModel], extending [PostEntity].
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

  /// Creates a [PostModel] from a database [map].
  factory PostModel.fromMap(Map<String, dynamic> map) {
    return PostModel(
      userId: map['userId'],
      postIdLocal: map['postIdLocal'],
      postIdX: map['postIdX'],
      content: map['content'],
      title: map['title'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt:
          map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
      scheduledAt: map['scheduledAt'] != null
          ? DateTime.parse(map['scheduledAt'])
          : null,
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

  /// Converts this [PostModel] to a [Map] for database insertion.
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

  /// Creates a [PostModel] from an existing [PostEntity], injecting [userId].
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

  /// Converts this [PostModel] into a base [PostEntity].
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
