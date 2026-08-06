import '../../core/error/result.dart';

/// Read/write access to a child's persisted completion state for
/// cross-cutting activities (Floor). Badge state is intentionally not here —
/// it's already generic in `ProgressRepository.hasBadge`/`awardBadge`, which
/// activities reuse directly by passing their activity id as the owner id.
abstract interface class ActivityProgressRepository {
  /// Whether [activityId] has been completed before.
  Future<Result<bool>> isActivityCompleted(String activityId);

  /// Marks [activityId] as completed. Idempotent — completing an
  /// already-completed activity again just updates the timestamp.
  Future<Result<void>> markActivityCompleted(String activityId);
}
