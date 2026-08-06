import '../../core/error/result.dart';
import '../entities/badge_info.dart';

/// Read/write access to a child's persisted progress (Floor). This never
/// stores static content — only which beats/badges/quiz attempts happened.
abstract interface class ProgressRepository {
  /// Ids of beats already completed for [moduleId].
  Future<Result<Set<String>>> getCompletedBeatIds(String moduleId);

  /// Records that [beatId] within [moduleId] was completed.
  Future<Result<void>> markBeatCompleted(String moduleId, String beatId);

  /// Whether [badgeId] has already been earned for [moduleId].
  Future<Result<bool>> hasBadge(String moduleId, String badgeId);

  /// Records that [badge] was earned for [moduleId].
  Future<Result<void>> awardBadge(String moduleId, BadgeInfo badge);

  /// Every badge id earned so far, across every module/activity/streak
  /// owner — used to build the child's full sticker collection (e.g. for
  /// Tuku's Den) without one query per possible owner.
  Future<Result<Set<String>>> getAllEarnedBadgeIds();

  /// Records the outcome of one quiz attempt.
  Future<Result<void>> saveQuizResult({
    required String moduleId,
    required String quizId,
    required int correctCount,
    required int totalCount,
  });
}
