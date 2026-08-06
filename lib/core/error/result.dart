import 'failures.dart';

/// Outcome of an operation that can fail: either a [Success] carrying a
/// value of type [T], or a [Failure] carrying a typed [AppFailure].
///
/// Repository and use case methods return `Future<Result<T>>` instead of
/// throwing, so every caller is forced to handle the failure path.
sealed class Result<T> {
  const Result();

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  /// Maps the success value or the failure into a single value of type [R].
  R fold<R>(R Function(T value) onSuccess, R Function(AppFailure failure) onFailure) {
    final self = this;
    return switch (self) {
      Success<T>(value: final value) => onSuccess(value),
      Failure<T>(failure: final failure) => onFailure(failure),
    };
  }
}

/// The operation completed with [value].
final class Success<T> extends Result<T> {
  const Success(this.value);

  final T value;
}

/// The operation could not complete; see [failure] for why.
final class Failure<T> extends Result<T> {
  const Failure(this.failure);

  final AppFailure failure;
}
