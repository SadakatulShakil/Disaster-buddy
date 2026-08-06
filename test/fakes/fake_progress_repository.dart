import 'package:bipod_bondhu/core/error/result.dart';
import 'package:bipod_bondhu/domain/entities/badge_info.dart';
import 'package:bipod_bondhu/domain/repositories/progress_repository.dart';

/// In-memory [ProgressRepository] test double.
class FakeProgressRepository implements ProgressRepository {
  final Map<String, Set<String>> completedBeatIdsByModule = {};
  final Set<String> earnedBadgeIds = {};

  /// Number of times [awardBadge] was actually invoked — [earnedBadgeIds]
  /// alone can't distinguish "awarded once" from "awarded again" since
  /// adding an id already in the set is a no-op.
  int awardBadgeCallCount = 0;

  @override
  Future<Result<Set<String>>> getCompletedBeatIds(String moduleId) async =>
      Success(completedBeatIdsByModule[moduleId] ?? {});

  @override
  Future<Result<void>> markBeatCompleted(String moduleId, String beatId) async {
    completedBeatIdsByModule.putIfAbsent(moduleId, () => {}).add(beatId);
    return const Success(null);
  }

  @override
  Future<Result<bool>> hasBadge(String moduleId, String badgeId) async =>
      Success(earnedBadgeIds.contains(badgeId));

  @override
  Future<Result<void>> awardBadge(String moduleId, BadgeInfo badge) async {
    awardBadgeCallCount++;
    earnedBadgeIds.add(badge.id);
    return const Success(null);
  }

  @override
  Future<Result<Set<String>>> getAllEarnedBadgeIds() async => Success(Set.of(earnedBadgeIds));

  @override
  Future<Result<void>> saveQuizResult({
    required String moduleId,
    required String quizId,
    required int correctCount,
    required int totalCount,
  }) async =>
      const Success(null);
}
