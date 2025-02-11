/// A domain entity representing our app user in local storage.
/// For now we store:
/// - userId (from FirebaseAuth?),
/// - fullName,
/// - dateOfBirth,
/// - gender,
/// - xCredential (Twitter or "X" credential, optional),
/// - avatarUrl or local image path (not implemented yet).
class UserEntity {
  final String userId;        // e.g. from Firebase UID
  final String fullName;
  final DateTime dateOfBirth;
  final String gender;
  final String? avatarPath;



  UserEntity({
    required this.userId,
    required this.fullName,
    required this.dateOfBirth,
    required this.gender,
    this.avatarPath,
  });
}
