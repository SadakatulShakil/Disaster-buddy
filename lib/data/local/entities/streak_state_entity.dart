import 'package:floor/floor.dart';

/// Single-row table holding the child's current streak counters. `id` is
/// always 0 — there is exactly one child profile, so one row.
@Entity(tableName: 'streak_state', primaryKeys: ['id'])
class StreakStateEntity {
  const StreakStateEntity({
    this.id = 0,
    required this.currentStreak,
    required this.bestStreak,
    required this.freezesAvailable,
    this.lastCompletedDateKey,
  });

  final int id;
  final int currentStreak;
  final int bestStreak;
  final int freezesAvailable;

  /// Local calendar date (`yyyy-MM-dd`) of the most recent completion.
  final String? lastCompletedDateKey;
}
