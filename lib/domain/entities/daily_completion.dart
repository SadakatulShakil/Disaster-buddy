import 'package:equatable/equatable.dart';

/// A record that the child finished one day's daily challenge. Kept for
/// every completed day (never deleted), both to drive streak/chain-view
/// logic and — per Phase E1's design note — so a future "Tuku's Den"
/// showcase (Phase E2) can list what was played on which day without any
/// schema changes.
final class DailyCompletion extends Equatable {
  const DailyCompletion({
    required this.dateKey,
    required this.challengeId,
    required this.wasCorrect,
    required this.completedAt,
  });

  /// Local calendar date, `yyyy-MM-dd` (see `LocalDay`).
  final String dateKey;
  final String challengeId;
  final bool wasCorrect;
  final DateTime completedAt;

  @override
  List<Object?> get props => [dateKey, challengeId, wasCorrect, completedAt];
}
