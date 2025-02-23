// lib/core/usecases/usecase.dart

/// Represents an abstract use case that produces a result of type [Type]
/// and can accept parameters of type [Params].
///
/// Implementing classes must define the [call] method to perform
/// a specific business operation.
abstract class UseCase<Type, Params> {
  /// Executes the use case.
  Future<Type> call({Params params});
}
