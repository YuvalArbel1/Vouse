import 'package:vouse_flutter/core/resources/data_state.dart';

abstract class XAuthRepository {
  /// Initiates a sign-in to Twitter using OAuth 2.0 with PKCE.
  Future<DataState<String>> signInToX();
}
