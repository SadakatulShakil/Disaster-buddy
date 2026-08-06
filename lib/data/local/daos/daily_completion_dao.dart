import 'package:floor/floor.dart';

import '../entities/daily_completion_entity.dart';

@dao
abstract class DailyCompletionDao {
  @Query('SELECT * FROM daily_completions WHERE dateKey = :dateKey')
  Future<DailyCompletionEntity?> findByDate(String dateKey);

  @Query('SELECT * FROM daily_completions ORDER BY dateKey DESC LIMIT :limit')
  Future<List<DailyCompletionEntity>> findRecent(int limit);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertOrUpdate(DailyCompletionEntity entity);
}
