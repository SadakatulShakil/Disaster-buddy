import '../../core/constants/app_constants.dart';
import '../../core/error/result.dart';
import '../../core/utils/app_logger.dart';
import '../../domain/entities/activity.dart';
import '../../domain/repositories/activity_repository.dart';
import '../datasources/activity_asset_source.dart';

/// Loads activities from bundled JSON manifests via [ActivityAssetSource].
final class ActivityRepositoryImpl implements ActivityRepository {
  const ActivityRepositoryImpl(this._source);

  final ActivityAssetSource _source;

  @override
  Future<Result<Activity>> getActivity(String activityId) => _source.loadActivity(activityId);

  @override
  Future<Result<List<Activity>>> getActivities() async {
    final activities = <Activity>[];
    for (final activityId in AppConstants.implementedActivities) {
      final result = await _source.loadActivity(activityId);
      switch (result) {
        case Success<Activity>(value: final activity):
          activities.add(activity);
        case Failure<Activity>(failure: final failure):
          AppLogger.error('getActivities aborted: failed to load "$activityId": ${failure.message}');
          return Failure(failure);
      }
    }
    return Success(activities);
  }
}
