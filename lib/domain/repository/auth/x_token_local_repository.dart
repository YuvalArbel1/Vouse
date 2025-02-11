import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/domain/entities/x_auth_tokens.dart';

/// Abstract contract for storing tokens in secure storage
abstract class XTokenLocalRepository {
  Future<DataState<void>> saveTokens(XAuthTokens tokens);
  Future<DataState<XAuthTokens?>> getTokens();
  Future<DataState<void>> clearTokens();
}
