import 'package:floor/floor.dart';

import '../entities/progress_entity.dart';

@dao
abstract class ProgressDao {
  @Query('SELECT * FROM progress WHERE moduleId = :moduleId')
  Future<List<ProgressEntity>> findByModule(String moduleId);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertProgress(ProgressEntity entity);
}
