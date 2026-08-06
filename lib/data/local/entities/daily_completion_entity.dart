import 'package:floor/floor.dart';

/// A child's persisted completion of one day's daily challenge. Kept
/// forever (never deleted) — both streak/chain math and a future "Tuku's
/// Den" showcase (Phase E2) read this history.
@Entity(tableName: 'daily_completions', primaryKeys: ['dateKey'])
class DailyCompletionEntity {
  const DailyCompletionEntity({
    required this.dateKey,
    required this.challengeId,
    required this.wasCorrect,
    required this.completedAt,
  });

  /// Local calendar date, `yyyy-MM-dd` (see `LocalDay`).
  final String dateKey;
  final String challengeId;
  final bool wasCorrect;

  /// Epoch millis.
  final int completedAt;
}
