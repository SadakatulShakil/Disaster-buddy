import 'package:floor/floor.dart';

import '../entities/badge_entity.dart';

@dao
abstract class BadgeDao {
  @Query('SELECT * FROM badges WHERE moduleId = :moduleId')
  Future<List<BadgeEntity>> findByModule(String moduleId);

  @Query('SELECT * FROM badges')
  Future<List<BadgeEntity>> findAll();

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertBadge(BadgeEntity entity);
}
