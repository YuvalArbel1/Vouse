// lib/core/resources/data_state.dart

import 'package:dio/dio.dart';

/// An abstraction for data-layer operations that can succeed or fail.
///
/// [data] may be null on error, and [error] may be null on success.
abstract class DataState<T> {
  final T? data;
  final DioException? error;

  const DataState({this.data, this.error});
}

/// A successful data state, containing a non-null [data] payload.
class DataSuccess<T> extends DataState<T> {
  const DataSuccess(T data) : super(data: data);
}

/// A failed data state, containing a [DioException] error.
class DataFailed<T> extends DataState<T> {
  const DataFailed(DioException error) : super(error: error);
}
