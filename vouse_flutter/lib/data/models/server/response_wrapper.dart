// lib/data/models/server/response_wrapper.dart

/// Generic wrapper for server API responses.
///
/// Our server API always returns a standard format with success/message/data fields.
/// This class provides a type-safe way to parse those responses.
class ResponseWrapper<T> {
  final bool success;
  final String? message;
  final T? data;

  ResponseWrapper({
    required this.success,
    this.message,
    this.data,
  });

  factory ResponseWrapper.fromJson(
      Map<String, dynamic> json,
      T Function(dynamic json) fromJsonT,
      ) {
    return ResponseWrapper<T>(
      success: json['success'] as bool,
      message: json['message'] as String?,
      data: json['data'] != null ? fromJsonT(json['data']) : null,
    );
  }

  Map<String, dynamic> toJson(Object? Function(T value) toJsonT) {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    if (message != null) {
      data['message'] = message;
    }
    if (this.data != null) {
      data['data'] = toJsonT(this.data as T);
    }
    return data;
  }
}