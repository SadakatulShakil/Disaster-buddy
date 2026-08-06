import 'package:floor/floor.dart';

import '../entities/streak_state_entity.dart';

@dao
abstract class StreakStateDao {
  @Query('SELECT * FROM streak_state WHERE id = 0')
  Future<StreakStateEntity?> find();

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> save(StreakStateEntity entity);
}
