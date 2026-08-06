import '../../core/error/result.dart';
import '../entities/badge_info.dart';
import '../repositories/activity_progress_repository.dart';
import '../repositories/progress_repository.dart';

/// Marks an activity completed and, the first time only, awards its badge
/// (if it has one) — reusing the same `ProgressRepository.hasBadge`/
/// `awardBadge` the module badges use, keyed by the activity id.
final class CompleteActivity {
  const CompleteActivity({
    required ActivityProgressRepository activityProgressRepository,
    required ProgressRepository progressRepository,
  })  : _activityProgressRepository = activityProgressRepository,
        _progressRepository = progressRepository;

  final ActivityProgressRepository _activityProgressRepository;
  final ProgressRepository _progressRepository;

  /// Returns whether [badge] was newly awarded by this call — false if
  /// there's no badge, or it was already earned (e.g. replaying a completed
  /// activity never re-awards it).
  Future<Result<bool>> call({required String activityId, BadgeInfo? badge}) async {
    final markResult = await _activityProgressRepository.markActivityCompleted(activityId);
    if (markResult case Failure<void>(failure: final failure)) {
      return Failure(failure);
    }

    if (badge == null) return const Success(false);

    final hasBadgeResult = await _progressRepository.hasBadge(activityId, badge.id);
    final alreadyHasBadge = hasBadgeResult is Success<bool> && hasBadgeResult.value;
    if (alreadyHasBadge) return const Success(false);

    final awardResult = await _progressRepository.awardBadge(activityId, badge);
    if (awardResult case Failure<void>(failure: final failure)) {
      return Failure(failure);
    }
    return const Success(true);
  }
}
