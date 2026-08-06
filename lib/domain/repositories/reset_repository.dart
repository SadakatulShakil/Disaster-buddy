import '../../core/error/result.dart';

/// Parent-controlled, destructive resets of a child's persisted progress.
/// Every method is atomic (all-or-nothing) and, where it removes a badge,
/// also prunes that sticker out of Tuku's Den — a child can never end up
/// with an invalid Adventure Map or an unearned sticker on display.
abstract interface class ResetRepository {
  /// Clears every hazard module's progress/quiz results/badge and every
  /// activity's progress/badge. Preserves the streak, daily-challenge
  /// history, and the Den's theme/streak stickers.
  Future<Result<void>> resetLearningProgress();

  /// Clears one hazard module's progress/quiz results/badge. Every other
  /// module, activity, the streak, and the Den are untouched.
  Future<Result<void>> resetSingleModule(String moduleId);

  /// Wipes every progress/engagement table back to a brand-new child's
  /// state. Never touches device preferences (language/sound/speed).
  Future<Result<void>> resetEverything();
}
