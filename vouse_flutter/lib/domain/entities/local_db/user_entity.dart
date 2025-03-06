// lib/domain/entities/local_db/user_entity.dart

/// Represents a user within the app's domain.
///
/// Typically includes:
/// - A [userId] (e.g. Firebase UID),
/// - Basic profile info like [fullName] and [gender],
/// - [dateOfBirth],
/// - An optional [avatarPath] for storing a local image or avatar URL.
class UserEntity {
  final String userId;
  final String fullName;
  final DateTime dateOfBirth;
  final String gender;
  final String? avatarPath;

  /// Creates a [UserEntity] with mandatory fields for ID, name, DOB, gender,
  /// and an optional [avatarPath].
  UserEntity({
    required this.userId,
    required this.fullName,
    required this.dateOfBirth,
    required this.gender,
    this.avatarPath,
  });
}
