/// Typed hierarchy of failures that can be carried by a [Failure] result.
///
/// Every subtype carries a [message] that is safe to show to a child user,
/// plus an optional [cause] and [stackTrace] for logging at the boundary
/// where the failure is first caught.
sealed class AppFailure {
  const AppFailure(this.message, {this.cause, this.stackTrace});

  /// User-safe message. Never contains raw exception text.
  final String message;

  /// The original exception/error that triggered this failure, if any.
  final Object? cause;

  final StackTrace? stackTrace;

  @override
  String toString() => '$runtimeType: $message';
}

/// A content manifest (JSON) was missing required fields or malformed.
final class ContentParseFailure extends AppFailure {
  const ContentParseFailure(super.message, {super.cause, super.stackTrace});
}

/// A referenced asset (manifest, image, audio) could not be found in the bundle.
final class AssetNotFoundFailure extends AppFailure {
  const AssetNotFoundFailure(super.message, {super.cause, super.stackTrace});
}

/// A Floor/sqlite operation failed.
final class DatabaseFailure extends AppFailure {
  const DatabaseFailure(super.message, {super.cause, super.stackTrace});
}

/// Anything not covered by the above. Kept last-resort so we never swallow
/// an exception silently.
final class UnknownFailure extends AppFailure {
  const UnknownFailure(super.message, {super.cause, super.stackTrace});
}

/// A requested state change was invalid (e.g. placing a sticker that was
/// never earned, or targeting a shelf slot that doesn't exist) — a friendly
/// no-op rather than a crash. Never a sign of a bug; often just a stale UI
/// racing a fresh state.
final class ValidationFailure extends AppFailure {
  const ValidationFailure(super.message, {super.cause, super.stackTrace});
}
