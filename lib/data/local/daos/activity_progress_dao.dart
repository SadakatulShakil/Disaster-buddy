import 'package:floor/floor.dart';

import '../entities/activity_progress_entity.dart';

@dao
abstract class ActivityProgressDao {
  @Query('SELECT * FROM activity_progress WHERE activityId = :activityId')
  Future<ActivityProgressEntity?> findByActivity(String activityId);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertOrUpdate(ActivityProgressEntity entity);
}
