import 'package:flutter/foundation.dart';

/// Thin wrapper over [debugPrint] so logging is a no-op in release builds
/// and every call site is consistent. Never use `print()` directly.
class AppLogger {
  AppLogger._();

  /// Logs a recoverable failure. Call this once, at the boundary where the
  /// failure is first caught — never swallow an exception silently.
  static void error(String message, {Object? error, StackTrace? stackTrace}) {
    if (kReleaseMode) return;
    debugPrint('[ERROR] $message${error != null ? ' | $error' : ''}');
    if (stackTrace != null) debugPrint(stackTrace.toString());
  }

  /// Logs a non-error diagnostic message.
  static void info(String message) {
    if (kReleaseMode) return;
    debugPrint('[INFO] $message');
  }
}
