import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/domain/entities/user_entity.dart';

/// Defines local DB methods for user data
abstract class UserLocalRepository {
  /// Save (insert or update) the user in local DB
  Future<DataState<void>> saveUser(UserEntity user);

  /// Get user by their userId
  Future<DataState<UserEntity?>> getUser(String userId);
}
