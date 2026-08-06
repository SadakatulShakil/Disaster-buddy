import '../../core/error/result.dart';
import '../entities/activity.dart';
import '../entities/collectible_sticker.dart';
import '../entities/hazard_module.dart';
import '../repositories/progress_repository.dart';
import '../services/streak_milestones.dart';
import 'get_activities.dart';
import 'get_modules.dart';

/// Loads a child's full sticker collection for Tuku's Den: every badge the
/// app can award — hazard modules, cross-cutting activities, and streak
/// milestones — each flagged [CollectibleSticker.earned] or not. Unearned
/// entries are included deliberately (never filtered out) so the
/// collection tray can show them as an aspirational locked placeholder
/// rather than simply omitting them.
final class GetEarnedCollection {
  const GetEarnedCollection({
    required GetModules getModules,
    required GetActivities getActivities,
    required ProgressRepository progressRepository,
  })  : _getModules = getModules,
        _getActivities = getActivities,
        _progressRepository = progressRepository;

  final GetModules _getModules;
  final GetActivities _getActivities;
  final ProgressRepository _progressRepository;

  Future<Result<List<CollectibleSticker>>> call() async {
    final modulesResult = await _getModules();
    if (modulesResult case Failure<List<HazardModule>>(failure: final failure)) {
      return Failure(failure);
    }
    final modules = (modulesResult as Success<List<HazardModule>>).value;

    final activitiesResult = await _getActivities();
    if (activitiesResult case Failure<List<Activity>>(failure: final failure)) {
      return Failure(failure);
    }
    final activities = (activitiesResult as Success<List<Activity>>).value;

    final earnedResult = await _progressRepository.getAllEarnedBadgeIds();
    if (earnedResult case Failure<Set<String>>(failure: final failure)) {
      return Failure(failure);
    }
    final earnedIds = (earnedResult as Success<Set<String>>).value;

    final sortedModules = [...modules]..sort((a, b) => a.order.compareTo(b.order));

    final stickers = <CollectibleSticker>[
      for (final module in sortedModules)
        CollectibleSticker(
          badge: module.badge,
          earned: earnedIds.contains(module.badge.id),
          sourceKind: CollectibleSourceKind.module,
          sourceLabel: module.title,
        ),
      for (final activity in activities)
        if (activity.badge != null)
          CollectibleSticker(
            badge: activity.badge!,
            earned: earnedIds.contains(activity.badge!.id),
            sourceKind: CollectibleSourceKind.activity,
            sourceLabel: activity.title,
          ),
      for (final length in StreakMilestones.lengths)
        if (StreakMilestones.badgeFor(length) case final badge?)
          CollectibleSticker(
            badge: badge,
            earned: earnedIds.contains(badge.id),
            sourceKind: CollectibleSourceKind.streak,
            sourceLabel: badge.title,
            streakLength: length,
          ),
    ];

    return Success(stickers);
  }
}
