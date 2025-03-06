// lib/domain/repository/local_db/user_local_repository.dart

import 'package:vouse_flutter/core/resources/data_state.dart';
import '../../entities/local_db/user_entity.dart';

/// Defines local storage operations for user data.
abstract class UserLocalRepository {
  /// Saves or updates [user] in the local database.
  Future<DataState<void>> saveUser(UserEntity user);

  /// Retrieves a user by [userId], returning a [DataState<UserEntity?>].
  Future<DataState<UserEntity?>> getUser(String userId);
}
