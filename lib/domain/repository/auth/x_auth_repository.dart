import 'package:vouse_flutter/core/resources/data_state.dart';

import '../../entities/x_auth_tokens.dart';

abstract class XAuthRepository {
  /// Returns DataState with both access & refresh tokens
  Future<DataState<XAuthTokens>> signInToX();
}
