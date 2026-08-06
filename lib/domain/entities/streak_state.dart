import 'package:equatable/equatable.dart';

/// A child's persisted "chain with grace" daily-challenge streak. Never
/// carries a punishing "you lost your streak" concept — a gap either
/// consumes a freeze (preserving [currentStreak]) or gently starts a new
/// chain from zero; [freezesAvailable] is a separate, never-forfeited
/// resource the child has earned.
final class StreakState extends Equatable {
  const StreakState({
    required this.currentStreak,
    required this.bestStreak,
    required this.freezesAvailable,
    this.lastCompletedDateKey,
  });

  /// A brand-new child starts with a full pool of freezes — grace is
  /// available from day one, not something earned only after a first week.
  const StreakState.initial()
      : currentStreak = 0,
        bestStreak = 0,
        freezesAvailable = 2,
        lastCompletedDateKey = null;

  final int currentStreak;
  final int bestStreak;
  final int freezesAvailable;

  /// Local calendar date (`yyyy-MM-dd`) of the most recent completion, or
  /// null if the child has never completed a daily challenge.
  final String? lastCompletedDateKey;

  StreakState copyWith({
    int? currentStreak,
    int? bestStreak,
    int? freezesAvailable,
    String? lastCompletedDateKey,
  }) {
    return StreakState(
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      freezesAvailable: freezesAvailable ?? this.freezesAvailable,
      lastCompletedDateKey: lastCompletedDateKey ?? this.lastCompletedDateKey,
    );
  }

  @override
  List<Object?> get props => [currentStreak, bestStreak, freezesAvailable, lastCompletedDateKey];
}
